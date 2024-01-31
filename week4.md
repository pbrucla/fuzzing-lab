# Week 4: Writing Harnesses

In previous weeks, we fuzzed libraries by using existing programs that link to the libraries as fuzz targets.
This time, we will be writing our own harness programs.
One of the advantages of this is that we can use persistent mode, which avoids the overhead from spawning a new process for every input by using one process to test multiple inputs.
Also the input can be passed to the target process using shared memory instead of temporary files, which further improves performance.
These two improvements will make our fuzzing over 30 times faster!
In more advanced fuzzing, custom harnesses can be used to transform the input in order to increase coverage.

The library that we will fuzz today is [libcue](https://github.com/lipnitsk/libcue), which parses cue files that describe tracks on CDs.
A recent vulnerability in libcue made it possible to hack anyone using the popular GNOME desktop environment for Linux by tricking them into downloading one malicious file with no further interaction required.
Kevin Backhouse from the GitHub Security Lab wrote two blog posts describing the [vulnerability](https://github.blog/2023-10-09-coordinated-disclosure-1-click-rce-on-gnome-cve-2023-43641/) and how he [exploited](https://github.blog/2023-12-06-cueing-up-a-calculator-an-introduction-to-exploit-development-on-linux/) it.
I highly recommend reading them if you're interested in this kind of stuff, but maybe do so after today's meeting so that you can try identifying the vulnerability yourself.

## Editing files in Docker

For this exercise, we'll need to edit files inside a Docker container, which you can do using [Visual Studio Code](https://code.visualstudio.com/Download).
Install it if you don't have it already, and also install the Dev Containers extension using the extension manager which you can access from the button on the left bar.
You can continue while waiting for things to download.

## Building libcue

Clone the libcue repository using Git in a Docker container.
Inside the repository, run `git switch -d 78279d0` to switch to the version right before the vulnerability was fixed.
This version happens to have a bug that causes a build error, so run `git cherry-pick -n 3619af5` to apply the fix for it.
libcue depends on `flex` and `bison`, so install these using `dnf`.

The commands for building libcue are a bit different from what we did previously, since libcue uses a program called CMake to generate Makefiles instead of a `configure` script.
Create a directory called `build` for storing the files generated during the build and move into it.
Then run this command to generate the Makefile:

```sh
CC=hfuzz-clang CXX=hfuzz-clang++ cmake -DCMAKE_INSTALL_PREFIX=/fuzz/install -DCMAKE_BUILD_TYPE=Release ..
```

The `-DCMAKE_INSTALL_PREFIX=/fuzz/install` option sets the installation directory like the `--prefix` option that we used previously.
The `-DCMAKE_BUILD_TYPE=Release` option enables compiler optimizations so that the compiled code will be faster.
The `..` at the end specifies the project directory, which is the parent of the current directory in this case. Use `make` to build and install libcue.
You can also run `make test` to run some tests that make sure the built library works.

## Writing a harness

Now we will write a C program which takes input from the fuzzer and passes it to libcue.
Start VS Code, and open the command palette with CTRL+SHIFT+P.
Use the Attach to Running Container command to [attach to your Docker container](https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container).
This should open a new window where you can edit files inside the container.

Our fuzz target will follow a common style that originated from [libFuzzer](https://llvm.org/docs/LibFuzzer.html).
This means that we can use the same code for other fuzzers like [AFL++](https://aflplus.plus/).
Create a file named `harness.c` inside the `/fuzz` directory.
Now you'll need to write a C function with the following signature:

```c
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
```

The first argument is a pointer to an array of bytes containing the input data, and the second argument is the length of the input.
If we want to reject an input and tell the fuzzer to not add it to the corpus even if it seems interesting, the function should return -1.
Otherwise, it should return 0.
You should include `stdint.h` for the definition of `uint8_t`.

The function in libcue that we will be calling has this signature:

```c
Cd* cue_parse_string(const char*)
```

It takes a pointer to a null-terminated string and returns a pointer to a struct containing information parsed from the cue data.
The input that we get from the fuzzer is a sequence of arbitrary bytes which is not necessarily null-terminated, so we'll need to copy it to a bigger buffer and add a null byte to the end.

Use the [`malloc`](https://en.cppreference.com/w/c/memory/malloc) function from the C standard library to allocate a buffer that is one byte bigger than the input.
You should include `stdlib.h` in order to use `malloc`.
Store the pointer that `malloc` returns in a `char` pointer variable.
You should check if the returned pointer is null, which indicates that the allocation failed.
Note that `nullptr` doesn't exist in C, so you have to use `NULL` instead.
If `malloc` returned a null pointer, then your function should return -1 since since this error isn't caused by a bug in libcue.

Next, use [`memcpy`](https://en.cppreference.com/w/c/string/byte/memcpy) from `string.h` to copy the input data into the newly-allocated buffer, and then set the last byte of the buffer to a null character.
Call `cue_parse_string` from `libcue.h` with a pointer to the buffer and save the return value in a `Cd` pointer variable.
If the result is not null, free it with the `cd_delete` function to avoid leaking memory.
Here's the signature of `cd_delete`:

```c
void cd_delete(Cd* cd)
```

Make sure to also free the buffer where we copied the input using the [`free`](https://en.cppreference.com/w/c/memory/free) function, and don't forget to return 0.

## Compiling the harness

Use this command to compile the harness:

```sh
hfuzz-clang harness.c -o harness -Wall -Wextra -pedantic -O3 -fsanitize=fuzzer -I install/include -L install/lib64 -lcue
```

We run `hfuzz-clang` and give it our `harness.c` file.
`-o harness` tells it to output the program to a file named `harness`.
`-Wall -Wextra -pedantic` enables compiler warnings that catch some bugs.
`-O3` enables optimizations that make the code faster.
`-fsanitize=fuzzer` tells the compiler that we're using a libFuzzer-style harness.
The compiler will automatically insert code that repeatedly reads input from the fuzzer and calls our `LLVMFuzzerTestOneInput` function.
`-I install/include` tells the compiler where to search for the libcue header files, and `-L install/lib64` sets the directory where the compiler will search for the compiled libcue file.
Lastly, `-lcue` makes the compiler link our harness with libcue.
This option has to go after `harness.c` because of the way the linker loads the files.

Now you should have a `harness` program in your current directory.
You can run it with an input file as the argument, and the code inserted by the compiler will automatically call `LLVMFuzzerTestOneInput` with the contents of the file.

## Fuzzing

Create a directory named `seeds` where we'll store our seed corpus and run `cp libcue/t/issue10.cue seeds` to copy a test file from libcue into the directory.
Now run Honggfuzz with the usual arguments on the harness, but don't give any arguments to the harness.
Honggfuzz will automatically detect that we are using persistent mode.
The speed should be tens of thousands of executions per second, and you should get a crash in less than a minute.
The bug that caused the vulnerability is pretty simple, so I encourage you to try to find the root cause of the crash if you know how to use GDB.
Note that there are some other bugs in this version of libcue; the one that caused the vulnerability is in a function named `track_set_index`.
