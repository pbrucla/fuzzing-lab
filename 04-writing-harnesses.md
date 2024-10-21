# Week 4: Writing Harnesses

In previous weeks, we fuzzed libraries by using existing programs that link to the libraries as fuzz targets.
This time, we will be **writing our own harness programs**.

Using a custom harness has two primary benefits:
1. **Persistant Mode**.
This avoids the overhead from spawning a new process for every input by using one process to test multiple inputs.
2. **Shared Memory.**
Inputs can be passed to the target process using shared memory instead of temporary files, which further improves performance.

These two improvements will make our fuzzing over **30x faster**!
In more advanced fuzzing, custom harnesses can be used to transform the input in order to increase coverage.

The library that we will fuzz today is [libcue](https://github.com/lipnitsk/libcue), which parses cue files that describe tracks on CDs.
A recent vulnerability in libcue made it possible to hack anyone using the popular GNOME desktop environment for Linux by tricking them into downloading one malicious file with no further interaction required.

## Building libcue

Create a new directory for this week's activity and move into it.

```sh
mkdir libcue/
cd libcue/
```

Clone the libcue repository using Git on the fuzzing server.

```sh
git clone https://github.com/lipnitsk/libcue.git
cd libcue/
```

Inside the repository, we need to switch to the version of the code right before the vulnerability was fixed.
This version happens to have a bug that causes a build error, so we will also apply the fix for it.
This can be done using the followiing two `git` commands:

```sh
git switch -d 78279d0
git cherry-pick -n 3619af5
```

The commands for building libcue are a bit different from what we did previously, since libcue uses a program called CMake to generate Makefiles instead of a `configure` script.
Create a directory inside the repository called `build` for storing the files generated during the build and move into it.

```sh
mkdir build/
cd build/
```

Then run this command to generate the Makefile:

```sh
CC=hfuzz-clang CXX=hfuzz-clang++ cmake -DCMAKE_INSTALL_PREFIX="$HOME/libcue/install" -DCMAKE_BUILD_TYPE=Release ..
```

The `-DCMAKE_INSTALL_PREFIX="$HOME/libcue/install"` option sets the installation directory like the `--prefix` option that we used previously.
The `-DCMAKE_BUILD_TYPE=Release` option enables compiler optimizations so that the compiled code will be faster.
The `..` at the end specifies the project directory, which is the parent of the current directory in this case.
Use `make` to build and install libcue.

```sh
make
make install
```

> [!NOTE]
> What does running `make test` do?

## Writing a Harness

Now we will write a C program which takes input from the fuzzer and passes it to libcue.
On the server, you can use the following command to open Visual Studio Code in your browser.
Follow the instructions from this command.

```sh
code tunnel
```

Our fuzz target will follow a common style that originated from [libFuzzer](https://llvm.org/docs/LibFuzzer.html).
This means that we can use the same code for other fuzzers like [AFL++](https://aflplus.plus/).
Create a file named `harness.c` inside the `$HOME/libcue` directory.
Now you'll need to write a C function with the following signature:

```c
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
```

The first argument is a pointer to an array of bytes containing the input data, and the second argument is the length of the input.
If we want to reject an input and tell the fuzzer to not add it to the corpus even if it seems interesting, the function should return -1.
Otherwise, it should return 0.
You should include `stdint.h` for the definition of `uint8_t`.

You can use the following as starter code for `harness.c`:

```c
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <libcue.h>

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    // TODO: Add your fuzzing code here

    return 0;
}

```

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

> [!NOTE]
> Why should we return -1 if `malloc` returns a null pointer?

Next, use [`memcpy`](https://en.cppreference.com/w/c/string/byte/memcpy) from `string.h` to copy the input data into the newly-allocated buffer, and then set the last byte of the buffer to a null character.
Call `cue_parse_string` from `libcue.h` with a pointer to the buffer and save the return value in a `Cd` pointer variable.
If the result is not null, free it with the `cd_delete` function to avoid leaking memory.
Here's the signature of `cd_delete`:

```c
void cd_delete(Cd* cd)
```

Make sure to also free the buffer where we copied the input using the [`free`](https://en.cppreference.com/w/c/memory/free) function, and don't forget to return 0.

> [!NOTE]
> Why can we include `libcue.h` in the harness using angle brackets (`<libcue.h>`) instead of quotes (`"libcue.h"`)?

## Compiling the Harness

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

> [!NOTE]
> What do the values of `data` and `size` represent in the `LLVMFuzzerTestOneInput` function with respect to the input file?

## Fuzzing

Create a directory named `seeds` where we'll store our seed corpus and run the following command to copy a test file from libcue into the directory.

```sh
cp libcue/t/issue10.cue seeds/
```

Now run Honggfuzz with the usual arguments on the harness, but don't give any arguments to the harness (i.e. don't add anything like `___FILE___`).
Honggfuzz will automatically detect that we are using persistent mode.
The speed should be tens of thousands of executions per second, and you should get a crash in less than a minute.

> [!NOTE]
> What is the Honggfuzz command you used to run the fuzzer with the harness?

## Triaging the Crash
If you have time, we encourage you to try to find the root cause of the crash using `gdb`.
Note that there are some other bugs in this version of libcue; the one that caused the vulnerability is in a function named `track_set_index`.

> [!NOTE]
> How do you run your harness with `gdb`?

> [!NOTE]
> How do you pass the produced crash file to the harness while running it with `gdb`?

> [!NOTE]
> After reaching the crash in `gdb`, what does the output of `bt` (backtrace) show you?

## Acknowledgements
Kevin Backhouse from the GitHub Security Lab wrote two blog posts describing the [vulnerability](https://github.blog/2023-10-09-coordinated-disclosure-1-click-rce-on-gnome-cve-2023-43641/) and how he [exploited](https://github.blog/2023-12-06-cueing-up-a-calculator-an-introduction-to-exploit-development-on-linux/) it.
We highly recommend reading them if you're interested in learning more!
