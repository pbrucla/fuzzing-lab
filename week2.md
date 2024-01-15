# Week 2: Basic Honggfuzz Usage

[Honggfuzz](https://honggfuzz.dev) is a easy-to-use fuzzer developed by Google which has found [many vulnerabilities](https://github.com/google/honggfuzz#trophies).
We will be using it to rediscover an infinite recursion denial-of-service vulnerability in [Xpdf](https://www.xpdfreader.com).

This exercise is based on [Fuzzing101 Exercise 1](https://github.com/antonio-morales/Fuzzing101/tree/main/Exercise%201).

## Differences

Due to differing environment, following differences need to be accounted for:

1. do not apt install stuff, it has already been dnf installed (use dnf install to install other stuff)
2. if you downloaded files locally, make sure to change file paths in commands!

## Fuzzing

We will be using honggfuzz in non-persistent fuzzing w/o instrumentation mode (`-x`). Let's break down what this means:

* non-persistent - we will re-run the entire process for each new input, this can be inefficient compared to persistent fuzzing as there is significant overhead in starting processes and we have to incur the app's startup time for every new input
* instrumentation - with instrumentation, we can check which branches are explored in the fuzzing and the fuzzer will mutate its inputs to test all branches. We will not be using instrumentation, at least for this first fuzz

Look through the [usage](https://github.com/google/honggfuzz/blob/master/docs/USAGE.md) for such a command to run honggfuzz to fuzz `pdfinfo` with pdfs.
