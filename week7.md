# Week 7: Coverage Analysis

If you fuzzed a project and didn't find any crashes, you might want to check the code coverage to see if any parts of the code haven't been explored.
You can do this using tools like gcov and LLVM's SanitizerCoverage.

## Using LLVM SanitizerCoverage

Follow the [coverage analysis tutorial](https://appsec.guide/docs/fuzzing/c-cpp/techniques/coverage-analysis/) in the Trail of Bits Testing Handbook.
You can also read the [LLVM source-based code coverage documentation](https://clang.llvm.org/docs/SourceBasedCodeCoverage.html).

## Viewing HTML coverage reports

You have to copy HTML coverage reports from the server to your computer before viewing them.
You can do this using the `scp` command with this syntax: `scp -r <username>@fuzz.cerpfy.net:<remote_path> <local_path>`.
For example, to copy the `html_report` directory inside the `fuzz` directory on your server to the current directory on your computer, run `scp -r username@fuzz.cerpfy.net:fuzz/html_report .`.
The remote path is relative to your home directory unless it starts with a `/`.

## Improving coverage

There are several ways to help the fuzzer increase coverage.
If there's a function which doesn't have good coverage and is a [good fuzz target](https://github.com/google/fuzzing/blob/master/docs/good-fuzz-target.md), you can write a new harness that calls the function.
You can also manually construct test cases that increase coverage and add them to the corpus.
There are many advanced techniques like [structure-aware fuzzing](https://github.com/google/fuzzing/blob/master/docs/structure-aware-fuzzing.md) that are out of the scope of this lab.
You can read about some of them from the [resources](https://github.com/pbrucla/fuzzing-lab/blob/main/week5-6.md#fuzzing-resources) linked in last week's instructions.
