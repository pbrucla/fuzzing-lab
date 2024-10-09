# Week 2: Intro to Fuzzing

Fuzzing is a software testing technique that involves providing invalid, unexpected, or random data as inputs to a computer program.
This quarter, we will be delving into the world of fuzzing and learning how to use it to find bugs in software.
We will be learning how to use [Honggfuzz](https://honggfuzz.dev), a easy-to-use, security-oriented fuzzer developed by Google which has found [many vulnerabilities](https://github.com/google/honggfuzz#trophies).

This week, we will be using Honggfuzz to rediscover an **infinite recursion denial-of-service vulnerability** in [Xpdf](https://www.xpdfreader.com). This exercise is based on [Fuzzing101 Exercise 1](https://github.com/antonio-morales/Fuzzing101/tree/main/Exercise%201).

**The best way to learn is by doing!** We recommend that you type out the commands in this exercise (except for URLs) instead of copying and pasting them.
This will help you remember things.
You should try to understand what each command line argument does rather than memorize the whole command. We have left some guiding questions to help you think about what each command does.
If you have any questions, feel free to ask one of the officers/members running the lab.

> [!NOTE]
> There will be many friendly questions in this format that will help you learn more about fuzzing and computers in general.
> Please try to think about these questions as you try to re-discover the vulnerability in Xpdf.
> Being able to think about open-ended questions is a skill that will help you in software!

## Setup

All of the exercises and tooling needed to complete the labs are included on a Fuzzing Server we have set up for this lab.
You will need to SSH into the server to complete the exercises.
Follow the instructions to SSH into the server.

## Fuzzing Xpdf

### Instrumentation

To fuzz effectively, the fuzzer needs a way to monitor the execution of the target program so that it knows which inputs generate interesting new behavior.
We will compile the target with a special compiler which inserts instrumentation code that allows Honggfuzz to track code coverage.
Honggfuzz can also monitor the target using hardware features on some CPUs or the QEMU emulator.

After connecting to the server, download the Xpdf source code using the `curl` utiliy by running the following.
The downloaded file is a tar archive compressed using gzip which you can extract using `tar`.

```shell
curl -LO 'https://dl.xpdfreader.com/old/xpdf-3.02.tar.gz'
tar -xvzf xpdf-3.02.tar.gz
```

The `-L` flag tells curl to follow redirects, and the `-O` flag makes curl automatically determine the output file name.
For the `tar` command, `x` means extract, `v` means verbose (print out file names while extracting), `z` means the file is compressed with gzip, and `f` means read from the file named in the next argument instead of stdin.

Change your directory into the resulting `xpdf-3.02` directory.

```shell
cd xpdf-3.02/
```

Now we will build Xpdf using the GNU build system.
First, generate a Makefile containing the commands that need to be executed in order to build Xpdf.
This is done by running the `configure` script shown below.

```shell
CC=hfuzz-clang CXX=hfuzz-clang++ ./configure --prefix=/fuzz/install
```

`CC=hfuzz-clang CXX=hfuzz-clang++` sets the C and C++ compilers to the Honggfuzz compilers which will instrument the program.
The `--prefix` option sets the directory where Xpdf will be installed after it is built. Next, run `make -j <num_cores>` where `<num_cores>` is the number of CPU cores on your computer, which you can determine by running the `nproc` command.
This will compile Xpdf by executing the commands in the Makefile.

```make
make -j $(nproc)
make install
```

The `-j` option tells Make how many jobs to run in parallel. `make install` installs the compiled program (Xpdf) into the directory we specified earlier.
Go back to our `fuzz `directory with `cd ..`.
If you run `ls install/bin` now you should see several executables including `pdftotext`, which is the one that we will fuzz.

> [!NOTE]
> What would happen if we removed `CC=hfuzz-clang CXX=hfuzz-clang++` from the commands?

> [!NOTE]
> Would the fuzzing work?

> [!NOTE]
> Would it be more efficient?

### Building a Seed Corpus

To help Honggfuzz find interesting inputs, we will give it a few small examples of valid PDF files as part of the **seed corpus**.
Create a directory to hold these files and download some sample PDFs!

```shell
mkdir pdf_examples
cd pdf_examples/
```

Your task in this part is to try and **build a seed corpus**.
In this case, since Xpdf takes PDFs as input, we will download some sample PDFs to use as the seed corpus.
You can download the sample PDFs using the `curl` command shown below.

```
curl -LO 'https://github.com/mozilla/pdf.js-sample-files/raw/master/helloworld.pdf'
cd ..
```

> [!NOTE]
> Find some other PDF files (using Google or some other search engine) and add them to the seed corpus.

> [!NOTE]
> Try to keep each PDF relatively small (less than 100MB) so that Honggfuzz can process them quickly.

> [!NOTE]
> What command would you use to download a PDF file from a URL?

You can try running `pdftotext` on one of these files in the example shown below. `pdftotext` converts PDF files to plain text.

```shell
install/bin/pdftotext pdf_examples/helloworld.pdf -
```

The first argument is the input PDF file, and the second argument is the output text file (`-` means output to stdout).
It should output `Hello, world!` followed by a few blank lines.
Try to find 2-3 more PDF files to add to the seed corpus and test them with `pdftotext`.

> [!NOTE]
> What initial corpus size is ideal?

> [!NOTE]
> How big or small should the starting corpus be and how would this affect fuzzing outcomes?

### Dictionary

Another way that we can help Honggfuzz is use a dictionary, which is a list of common byte sequences for the file format that we're fuzzing.
Honggfuzz will try inserting these sequences into the input data and it will have a higher chance of creating partially-valid files that trigger new behavior in our target.
We'll use a PDF dictionary from AFL++, another popular fuzzer.
Download it with this command:

```sh
curl -LO 'https://github.com/AFLplusplus/AFLplusplus/raw/stable/dictionaries/pdf.dict'
```

### Fuzzing

Here's the fun part!
To start fuzzing, run the following command.

```shell
honggfuzz -i pdf_examples -o corpus -w pdf.dict -- install/bin/pdftotext ___FILE___ /dev/null
```

We give Honggfuzz the `pdf_examples` directory as the initial input corpus and tell it to store new interesting inputs in the `corpus` directory.
We also provide the dictionary with `-w pdf.dict`.
After the `--`, we specify the program to be fuzzed along with its arguments.
`___FILE___` is a placeholder which Honggfuzz will replace with the name of the input file, and we make the program output to `/dev/null`, which is a special file that discards anything written to it.

You should now see a fancy status panel.
Depending on your luck and how powerful your computer is, it may take anywhere from a few seconds to tens of minutes for Honggfuzz to find a crash.
Once Honggfuzz finds a crash, you can stop the fuzzing with CTRL-C.
You can also use the `--exit_upon_crash` flag to have Honggfuzz automatically stop when it finds a crash.
If you use this flag, you have to put it before the `--`, otherwise Honggfuzz will think that the flag is for the target program.
While Honggfuzz is running, you should see the corpus size increase and lines should keep appearing in the log.
The "Cov Update" value indicates how long it has been since the fuzzer found a new interesting input.
If the fuzzer isn't finding new inputs or the speed is below 100, then something is probably wrong.

> [!NOTE]
> How long did it take your computer to find the crash?

> [!NOTE]
> How long did it take the people around you?

> [!NOTE]
> Compare how long it took and try to come up with an explanation.

## Triaging the Crash

After Honggfuzz finds a crash, you can find the input that caused the crash in your current directory.
If you run `ls` and you should see a file named something like `SIGSEGV.PC.57605a.STACK.1976259487.CODE.1.ADDR.7fff4d888ff8.INSTR.call___0xffffffffffe904c6.fuzz`.
This contains the input that caused the crash.
There should also be a file named `HONGGFUZZ.REPORT.TXT`, and you can print it out by running the following command

```shell
cat HONGGFUZZ.REPORT.TXT
```

This file contains some details of the crash, including the backtrace which is the list of function calls that lead to the crash.
You'll see a few lines repeating over and over again because the crash was due to infinite recursion.
If you were investigating a new bug that you just found, the next step would be to figure out the root cause using tools like GDB.
That requires a lot more knowledge that we don't have time to cover and being familiar with the code that we're fuzzing, so we will stop here.

> [!NOTE]
> That file name `SIGSEGV.PC.57605a.STACK.1976259487.CODE.1.ADDR.7fff4d888ff8.INSTR.call___0xffffffffffe904c6.fuzz` is very long and has many words.
> What do each of those words/numbers mean and refer to?

> [!NOTE]
> Can you get any information on the crash from the name?

> [!NOTE]
> If you want to try and replicate the crash, how would you do it?
