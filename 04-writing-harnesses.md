# Week 4: Writing Harnesses

In previous weeks, we fuzzed libraries by using existing programs that link to the libraries as fuzz targets.
This time, we will be **writing our own harness programs**.

Using a custom harness has two primary benefits:
1. **Persistant Mode:**
   To avoid the overhead of spawning a new process for every input, one process can be used to test multiple inputs.
2. **Shared Memory:**
   Inputs can be passed to the target process using shared memory instead of temporary files, which further improves performance.

These two improvements will make our fuzzing over **30x faster**!
In more advanced fuzzing, custom harnesses can also be used to transform the input in order to increase coverage.

The library that we will fuzz today is [libcue](https://github.com/lipnitsk/libcue), which parses CUE files that describe tracks on CDs.
A vulnerability in libcue discovered last year made it possible to hack anyone using the popular GNOME desktop environment for Linux by tricking them into downloading one malicious file with no further interaction required.

## Building libcue

Create a new directory for fuzzing libcue called `fuzz-libcue` and move into it.
Download and extract the libcue source code from <https://github.com/lipnitsk/libcue/archive/refs/tags/v2.2.1.tar.gz>.

The commands for building libcue are a bit different from what we did previously, since libcue uses a program called CMake to generate Makefiles instead of a `configure` script.
Inside the `libcue-2.2.1` directory with the source code, create a directory called `build` and move into it.
This is where the files generated during the build will be stored.

Then run this command inside the `build` directory to generate the Makefile:

```sh
CC=hfuzz-clang CXX=hfuzz-clang++ cmake -DCMAKE_INSTALL_PREFIX="$HOME/libcue/install" -DCMAKE_BUILD_TYPE=Release ..
```

The `-DCMAKE_INSTALL_PREFIX="$HOME/fuzz-libcue/install"` option sets the installation directory like the `--prefix` option that we used previously.
The `-DCMAKE_BUILD_TYPE=Release` option enables compiler optimizations so that the compiled code will be faster.
The `..` at the end specifies the directory with the source code, which is the parent of the current directory in this case.
Use `make` to build and install libcue.

> [!NOTE]
> You can optionally run `make test` after building libcue.
> What does this command do?

## Writing a Harness

Now we will write a C program which takes input from the fuzzer and passes it to libcue.
In the `fuzz-libcue` directory, use the following command to open Visual Studio Code in your browser:

```sh
code tunnel
```

Follow the instructions from this command to sign in with either a Microsoft or GitHub account.

Our fuzz target will follow a common style that originated from [libFuzzer](https://llvm.org/docs/LibFuzzer.html).
This means that we can use the same code for other fuzzers like [AFL++](https://aflplus.plus/).
Create a file named `harness.c` with VS Code.
You'll need to write a C function with the following signature:

```c
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);
```

The first argument is a pointer to an array of bytes containing the input data, and the second argument is the length of the input.
If we want to reject an input and tell the fuzzer not to add it to the corpus regardless of the coverage feedback, the function should return -1.
For example, you might return -1 if the code that you're fuzzing requires the input to be at least a certain size and the input from the fuzzer is too short.
In all other cases, the function should return 0.

> [!NOTE]
> You should not return -1 if the code being fuzzed returns an error due to the input being invalid, because we want to test the code's ability to handle all inputs regardless of whether they are valid.

You should include `stdint.h` for the definition of `uint8_t`.

You can use the following starter code for `harness.c`:

```c
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <libcue.h>

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  // TODO: Add your fuzzing code here

  return 0;
}

```

The function in libcue that we will be calling has this signature:

```c
Cd* cue_parse_string(const char*);
```

It takes a pointer to a null-terminated string and returns a pointer to a struct containing information parsed from the CUE data.
The input that we get from the fuzzer is a sequence of arbitrary bytes which is not necessarily null-terminated, so we'll need to copy it to a bigger buffer and add a null byte to the end.

Use the [`malloc`](https://en.cppreference.com/w/c/memory/malloc) function from the C standard library to allocate a buffer that is one byte bigger than the input.
`malloc` is declared in `stdlib.h`, so you'll need to include this header.
Store the pointer that `malloc` returns in a `char` pointer variable.
It's good practice to check if the returned pointer is null, which indicates that the allocation failed.
If `malloc` returned a null pointer, then your function should return -1 since we can't pass this input to libcue.

> [!NOTE]
> `nullptr` doesn't exist in C, so you have to use `NULL` instead.

Next, use [`memcpy`](https://en.cppreference.com/w/c/string/byte/memcpy) from `string.h` to copy the input data into the newly-allocated buffer, and then set the last byte of the buffer to a null character.
Call `cue_parse_string` from `libcue.h` with a pointer to the buffer and save the return value in a `Cd` pointer variable.
If the result is not null, free it with the `cd_delete` function to avoid leaking memory.
Here's the signature of `cd_delete`:

```c
void cd_delete(Cd* cd);
```

Make sure to also free the buffer where we copied the input using the [`free`](https://en.cppreference.com/w/c/memory/free) function, and don't forget to return 0.

## Compiling the Harness

Use this command to compile the harness:

```sh
hfuzz-clang harness.c -o harness -Wall -Wextra -pedantic -O3 -fsanitize=fuzzer -I install/include -L install/lib64 -lcue
```

We run `hfuzz-clang` and give it our `harness.c` file.
Here's what all of the options do:
* `-o harness` tells the compiler to output the program to a file named `harness`.
* `-Wall -Wextra -pedantic` enables compiler warnings that catch some bugs.
* `-O3` enables optimizations that make the code faster.
* `-fsanitize=fuzzer` tells the compiler that we're using a libFuzzer-style harness.
  The compiler will automatically insert code that repeatedly reads input from the fuzzer and calls our `LLVMFuzzerTestOneInput` function.
* `-I install/include` adds the directory with the libcue header files to the preprocessor's search path so that it can find `libcue.h`.
* `-L install/lib64` adds the directory where the compiled libcue files are stored to the linker's search path so that the linker knows where to find the library.
* `-lcue` tells the linker to link our harness with libcue.
  This option has to go after `harness.c` because of the way the linker loads the files.

You should now have a `harness` program in your current directory.
You can run it with an input file as the argument, and the code inserted by the compiler will automatically call `LLVMFuzzerTestOneInput` with the contents of the file.

## Fuzzing

Create a directory named `seed` where we'll store our seed corpus and run the following command to copy a test file from libcue into the directory.

```sh
cp libcue-2.2.1/t/issue10.cue seed
```

Run Honggfuzz with the usual options on the `harness` program, but don't give any arguments to the harness (i.e. don't add anything like `___FILE___`).
Honggfuzz will automatically detect that we are using persistent mode.
The speed should be tens of thousands of executions per second, and you should get a crash in less than a minute.

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

This vulnerability was discovered by Kevin Backhouse from the GitHub Security Lab.
We highly recommend reading his blog posts [explaining the vulnerability](https://github.blog/2023-10-09-coordinated-disclosure-1-click-rce-on-gnome-cve-2023-43641/) and [how he exploited it](https://github.blog/2023-12-06-cueing-up-a-calculator-an-introduction-to-exploit-development-on-linux/) if you're interested in learning more!
