# Week 5: Coverage Analysis

In last week's activity, we wrote a custom harness to fuzz `libcue`. This activity will build upon that by showing you how to collect and analyze the **code coverage** achieved by the fuzzer.

Coverage tells us which parts of code in the target are actually executed upon running the target with certain test cases. While many fuzzers, including Honggfuzz, use some metric of coverage to guide their mutations, this coverage is not directly exposed to us for further analysis. 

We will be using LLVM's [SanitizerCoverage](https://clang.llvm.org/docs/SanitizerCoverage.html) interface and associated tooling to collect and view the coverage of our fuzzing corpus.

## Rebuilding libcue and harness

We will need to rebuild `libcue` and the harness with coverage instrumentation enabled. I recommend creating a new directory under your home directory called `cov-libcue` for this. The instructions are the same as in the activity from week 4 with the addition of `CFLAGS="-fprofile-instr-generate -fcoverage-mapping"` and changing `-DCMAKE_BUILD_TYPE=Release` to `-DCMAKE_BUILD_TYPE=Debug` when running CMake to generate the Makefile. 

`-fprofile-instr-generate` causes the compiler to insert profiling instructions into the generated code. Among other things, this will gather execution counts for blocks of code, thus enabling coverage analysis.

`-fcoverage-mapping` generates information to describe the mapping between the library's source code and the lower-level coverage instrumentation. This allows us to generate coverage reports that overlay execution counts with their associated ranges of source.

Using the Debug build type prevents optimizations which can reduce the quality of our coverage to source mapping. You will also need to recompile your harness with the two flags described above.

## Refuzzing

We will need a corpus to analyze coverage from. While you could use your corpus from the previous activity, I recommend fuzzing again for a longer period to generate a larger corpus.

This can be achieved by replacing the `--exit_upon_crash` option with `--run_time 60` which tells Honggfuzz to stop fuzzing after 60 seconds. Feel free to experiment with how different fuzzing times affect the coverage of the corpus.

## Collecting coverage

We need a custom program, let's call it an executor, to execute all entries in our corpus.
This program should read in a directory or list of files and execute each one with the
`LLVMFuzzerTestOneInput` function from our harness.
Feel free to write this on your own, but the source for a working executor is also provided below.
```c
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <string.h>
#include <stdint.h>

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

We can compile our executor as follows.

```
hfuzz-clang -fprofile-instr-generate -fcoverage-mapping harness.c executor.c -o executor -I install/include -L install/lib -lcue
```

The following command will generate the raw LLVM profile data from running with our corpus in `fuzz.profraw`.

```
LLVM_PROFILE_FILE=fuzz.profraw ./executor corpus 2>1 >/dev/null
```

We must now convert it to an indexed `.profdata` file using the following command.

```
llvm-profdata merge -sparse fuzz.profraw -o fuzz.profdata
```

With the profdata file and our `executor` binary, we can generate a coverage report with the following command.

```
llvm-cov report executor -instr-profile=fuzz.profdata -ignore-filename-regex="harness.c|executor.c"
```

Note that we ignore the `harness.c` and `executor.c` files since we don't care about their coverage.
This will output a high-level report detailing the coverage percentages for each source file. For more detailed output with source code overlay, we can run the following command. There will be a column to the left of the source code with a number denoting the amount of times that line of code was executed. Lines with counts of zero are highlighted in red to indicate they are not covered.

```
llvm-cov show executor -instr-profile=fuzz.profdata -ignore-filename-regex="harness.c|executor.c"
```

You can also add the absolute path of one of the source files at the end of the above command to show output for just that file. Viewing this detailed information in the command-line is not ideal, so we can generate an HTML based report using [LCOV](https://github.com/linux-test-project/lcov).

```
mkdir -p ~/public_html/report
llvm-cov export executor -instr-profile=fuzz.profdata -format=lcov >fuzz.lcov
genhtml --output-directory ~/public_html/report fuzz.lcov
```

We have set up a web server that exposes files under `$HOME/public_html` for all users. Visit `fuzz.acmcyber.com/~username` where `username` is your username on the fuzzing server to view these files.
You can click on the report directory and interact with the website to view high-level coverage details and source overlays.

## Acknowledgements
This activity is based on [this coverage analysis post from Trail of Bits](https://appsec.guide/docs/fuzzing/c-cpp/techniques/coverage-analysis/).
