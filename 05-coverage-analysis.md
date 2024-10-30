# Week 5: Coverage Analysis

In last week's activity, we wrote a custom harness to fuzz `libcue`.
This activity will build upon that by showing you how to collect and analyze the **code coverage** achieved by the fuzzer.

Coverage tells us which parts of code in the target are actually executed upon running the target with certain test cases.
While many fuzzers, including Honggfuzz, use some metric of coverage to guide their mutations, this coverage is not directly exposed to us for further analysis. 

We will be using LLVM's [SanitizerCoverage](https://clang.llvm.org/docs/SanitizerCoverage.html) interface and associated tooling to collect and view the coverage of our fuzzing corpus.

## Rebuilding libcue and the harness

We will need to rebuild `libcue` and the harness with coverage instrumentation enabled.
I recommend creating a new directory under your home directory called `cov-libcue` for this.

Download libcue from <https://github.com/lipnitsk/libcue/archive/refs/tags/v2.3.0.tar.gz>.
Last week, we fuzzed an old version of libcue that had a vulnerability, but this time we're using the latest version where the vulnerability has been fixed since we don't want crashes when we're trying to measure coverage.

We will build and install libcue using a similar process as last week, but we will use the `clang` compiler instead of `hfuzz-clang` since we don't want the Honggfuzz instrumentation.
To enable SanitizerCoverage, we'll have to add the compiler flags `-fprofile-instr-generate` and `-fcoverage-mapping`, which can be done by setting the `CFLAGS` environment variable when running CMake.
We will also use a debug build instead of a release build by changing `-DCMAKE_BUILD_TYPE=Release` to `-DCMAKE_BUILD_TYPE=Debug`.
This disables optimizations which might make the compiled code not directly correspond to the source code.
Here's the new CMake command:

```sh
CC=clang CFLAGS='-fprofile-instr-generate -fcoverage-mapping' cmake -DCMAKE_INSTALL_PREFIX="$HOME/cov-libcue/install" -DCMAKE_BUILD_TYPE=Debug ..
```

> [!NOTE]
> You might have noticed that we didn't set the `CXX` environment variable this time.
> `CC` sets the C compiler, while `CXX` sets the C++ compiler.
> Similarly, `CFLAGS` sets the C compiler flags and `CXXFLAGS` sets the C++ compiler flags.
> Since libcue is written in C, we only have to set `CC` and `CFLAGS`.
> For C++ projects, you should set `CXX` and `CXXFLAGS` instead.
> If the project uses both C and C++ or you're not sure, then you can set the environment variables for both languages like what we've been doing previously.

Remember to create a build directory before running CMake.
After running CMake, use `make` to build and install libcue like we did previously.

Last week we compiled our harness with `hfuzz-clang`, which provided code that calls the `LLVMFuzzerTestOneInput` function.
This week we're using `clang` without the Honggfuzz wrapper, so we'll need to have our own code that reads input from files and passes the data to our harness.
We'll call this code the "executor" and we can use the following implementation from the [Trail of Bits Testing Handbook](https://appsec.guide/docs/fuzzing/c-cpp/techniques/coverage-analysis/):

```c
#include <dirent.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);

void load_file_and_test(const char *filename) {
  FILE *file = fopen(filename, "rb");
  if (file == NULL) {
    printf("Failed to open file: %s\n", filename);
    return;
  }

  fseek(file, 0, SEEK_END);
  long filesize = ftell(file);
  rewind(file);

  uint8_t *buffer = malloc(filesize);
  if (buffer == NULL) {
    printf("Failed to allocate memory for file: %s\n", filename);
    fclose(file);
    return;
  }

  long read_size = (long)fread(buffer, 1, filesize, file);
  if (read_size != filesize) {
    printf("Failed to read file: %s\n", filename);
    free(buffer);
    fclose(file);
    return;
  }

  LLVMFuzzerTestOneInput(buffer, filesize);

  free(buffer);
  fclose(file);
}

int main(int argc, char **argv) {
  if (argc != 2) {
    printf("Usage: %s <directory>\n", argv[0]);
    return 1;
  }

  DIR *dir = opendir(argv[1]);
  if (dir == NULL) {
    printf("Failed to open directory: %s\n", argv[1]);
    return 1;
  }

  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (entry->d_type == DT_REG) {
      char filepath[1024];
      snprintf(filepath, sizeof(filepath), "%s/%s", argv[1], entry->d_name);
      load_file_and_test(filepath);
    }
  }

  closedir(dir);
  return 0;
}
```

Copy the code into a file named `executor.c` in your `cov-libcue` directory, and also copy the `harness.c` file that you wrote last week into this directory.
Compile the harness and executor with this command:

```sh
clang -fprofile-instr-generate -fcoverage-mapping harness.c executor.c -o executor -I install/include -L install/lib -lcue
```

## Collecting coverage data

The program that we just compiled will automatically write coverage information to a file specified in the `LLVM_PROFILE_FILE` environment variable when we run it.
The executor takes a single argument that specifies a directory and it will run our harness on all of the files in the directory.
We can run it on the corpus from last week like this:

```sh
LLVM_PROFILE_FILE=fuzz.profraw ./executor ../fuzz-libcue/corpus 2>/dev/null
```

The `2>/dev/null` at the end discards the output from libcue, since it prints a lot of error messages when it reads inputs that aren't valid CUE files.

This should create a `fuzz.profraw` file containing the raw coverage profile data in your current directory.
We must now convert it to an indexed `.profdata` file using the following command:

```sh
llvm-profdata merge fuzz.profraw -o fuzz.profdata
```
Now we'll generate an HTML report that will display the coverage data in a nice format.
We've set up a web server so that you can view the HTML report in your browser without having to download it to your computer first.
The web server will look for files to serve in the `public_html` directory inside your home directory.
Create this directory with the following command:

```sh
mkdir ~/public_html
```

Then generate the report inside the directory:

```sh
llvm-cov show executor -instr-profile=fuzz.profdata -format=html -output-dir ~/public_html/libcue-report
```

Note that we have to provide both the executor program and the coverage data file.

Change the file permissions of the report so that the web server can read it:

```sh
chmod -R +rX ~/public_html/libcue-report
```

In your web browser, visit `https://fuzz.acmcyber.com/~username/libcue-report` where `username` is your username on the fuzzing server.
You should see a page listing the source files and the coverage statistics of each file.
You can click on a file name to see the coverage data for each line.
In the line-by-line coverage report, the column between the line numbers and the code shows how many times each line was executed.

> [!NOTE]
> What do the red highlights show in the line-by-line coverage report?
> Why do some lines not have execution counts?
> Which parts of the code were never executed?
> Why is this the case?

## Acknowledgements

This activity is based on [the Coverage Analysis page from the Trail of Bits Testing Handbook](https://appsec.guide/docs/fuzzing/c-cpp/techniques/coverage-analysis/).
