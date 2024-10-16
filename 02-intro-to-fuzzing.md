# Week 2: Intro to Fuzzing

Fuzzing is a software testing technique that involves repeatedly executing a program with many randomized inputs.
This quarter, we will dive into the world of fuzzing and learn how to use it to find bugs in software.
We will be learning how to use [Honggfuzz](https://honggfuzz.dev), an easy-to-use, security-oriented fuzzer developed by Google which has found [many vulnerabilities](https://github.com/google/honggfuzz#trophies).
You do not need to install Honggfuzz since all of the tools needed for this lab are already installed on the server for you!

This week, we will be using Honggfuzz to rediscover an **infinite recursion denial-of-service vulnerability** in [Xpdf](https://www.xpdfreader.com), an open-source PDF reader.
This exercise is based on [Fuzzing101 Exercise 1](https://github.com/antonio-morales/Fuzzing101/tree/main/Exercise%201).

**The best way to learn is by doing!**
We recommend that you type out the commands in this exercise (except for URLs) instead of copying and pasting them, since this will help you remember them.
You should try to understand what each part of the command does rather than memorize the whole command.
We have left some guiding questions to help you with this.
If you have any questions, feel free to ask one of the officers running the lab.

> [!NOTE]
> There will be many friendly questions in this format that will help you learn more about fuzzing and computers in general.
> Please try to think about these questions as you work on the activity, and feel free to ask us for help if you don't know the answer.

## Setup

All of the exercises for this lab should be done on our fuzzing server.
If you haven't done so already, follow the [instructions](fuzzing-server-instructions.md) to set up access to the server.
Log into the server with SSH and run all of the commands for this lab on the server.

## Xpdf Instrumentation

To fuzz effectively, the fuzzer needs a way to monitor the execution of the target program so that it knows which test cases generate interesting new behavior.
We will compile the target with a special compiler which inserts instrumentation code that allows Honggfuzz to track which parts of the code is executed.

After connecting to the server, we will start by making a directory for fuzzing Xpdf.
Use the `mkdir` and `cd` commands to create an `xpdf` directory and move into it:

```sh
mkdir xpdf
cd xpdf
```

You can verify that you are in the correct directory by running `pwd`, which will print the absolute path to the current working directory.
This should output `/home/<username>/xpdf`.
Your current directory is also shown in the blue part of your shell prompt, where `~` represents your home directory.

Next, download the Xpdf source code using the `curl` utiliy by running the following command:

```sh
curl -LO 'https://dl.xpdfreader.com/old/xpdf-3.02.tar.gz'
```

The `-L` flag tells curl to follow redirects, and the `-O` flag makes curl automatically determine the output file name.
`-LO` is a shorthand that's equivalent to `-L -O`.

The downloaded file is a tar archive compressed using gzip, and it can be extracted with the `tar` command:

```sh
tar -xvzf xpdf-3.02.tar.gz
```

Here, `x` means extract, `v` means verbose (print out file names while extracting), `z` means the file is compressed with gzip, and `f` means read from the archive file named in the next argument instead of stdin.
You can learn more about these commands by running `man curl` and `man tar`.

`cd` into the resulting `xpdf-3.02` directory:

```sh
cd xpdf-3.02
```

Now we will build Xpdf using the GNU build system.
First, we will use the `configure` script provided by Xpdf to set some compile-time options:

```sh
CC=hfuzz-clang CXX=hfuzz-clang++ ./configure --prefix="$HOME/xpdf/install"
```

This generates a file called a Makefile which contains the compiler commands that need to be executed in order to compile Xpdf.
`CC=hfuzz-clang CXX=hfuzz-clang++` sets the C and C++ compilers to the Honggfuzz compilers which will instrument the program.
The `--prefix` option sets the directory where Xpdf will be installed after it is built, and `$HOME` is a shell variable which expands to the absolute path of your home directory (`/home/<username>`).
You can learn more about the options provided by the `configure` script by running `./configure --help`.

Next, run the `make` command, which will read the Makefile and execute the compiler commands in the right order:

```sh
make -j 16
```

The `-j` option tells Make how many jobs to run in parallel.
Our server has 16 CPU cores, so we tell Make to run up to 16 jobs in parallel in order to fully utilize the CPU.

Lastly, we run `make` again to install Xpdf in to the directory we specified in the `./configure` command earlier:

```sh
make install
```

Go back to our `xpdf` directory with `cd ..`.
If you run `ls install/bin`, you should see several executables including `pdftotext`, which is the one that we will fuzz.

> [!NOTE]
> What would happen if we removed `CC=hfuzz-clang CXX=hfuzz-clang++` from the commands?
> Would the fuzzing work?
> Would it be more efficient?

## Building a Seed Corpus

To help Honggfuzz find interesting test cases, we will give it a few small examples of valid PDF files as part of the **seed corpus**.
Create a directory to hold these files and move into it:

```sh
mkdir pdf_examples
cd pdf_examples
```

Search online for some small sample PDF files to include in the seed corpus.
The files should be at most 100 KB so that they can be processed quickly.
You can try search terms such as `pdf test files`.
Once you find a PDF file, copy the URL and download it on the server with `curl`.
For example, run the following command to download a test PDF file from the Mozilla PDF.js project.
You can use `curl` to dowload more PDF files.
Try to find 2-3 more files to add to your seed corpus.

```sh
curl -LO 'https://github.com/mozilla/pdf.js-sample-files/raw/master/helloworld.pdf'
```

Make sure you're using the direct URL to the PDF file, not the URL of a web page that contains or links to the PDF file.
Once you've downloaded a several PDFs, use the `ls` command to print out their sizes and check that they are at most 100 KB:

```sh
ls -lh
```

Also use the `file` command to check that the files are actually PDFs:

```sh
file *
```

Once you have the files, return to the `xpdf` directory:

```sh
cd ..
```

You can try running the `pdftotext` program from Xpdf on one of the PDF files:

```shell
install/bin/pdftotext pdf_examples/helloworld.pdf -
```

`pdftotext` converts PDF files to plain text.
The first argument is the input PDF file, and the second argument is the output text file.
Specifying `-` for the output file tells the program to output to stdout, which is displayed to our terminal in this case.
This should print `Hello, world!` followed by a few blank lines.

> [!NOTE]
> How does the size of the seed corpus affect the fuzzing process?

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
To start fuzzing, run the following command:

```sh
honggfuzz -i pdf_examples -o corpus -w pdf.dict --exit_upon_crash -- install/bin/pdftotext ___FILE___ /dev/null
```

We give Honggfuzz the `pdf_examples` directory as the initial seed corpus and tell it to store new interesting test cases in the `corpus` directory.
We also provide the dictionary with `-w pdf.dict`, and the `--exit_upon_crash` option tells Honggfuzz to automatically stop once it finds a test case that crashes the target program.
The target program is specified after the `--`, and any arguments after that are forwarded to it.
`___FILE___` is a placeholder which Honggfuzz will replace with the name of the file containing the test case (be careful, this has **three** underscores on each side of FILE, not two).
We don't care about the output of `pdftotext`, so we make it output to `/dev/null`, a special file that discards any data written to it.

You should now see a fancy status panel, and it should take at most a few minutes for Honggfuzz to find a crash.
If you need to stop Honggfuzz early, press CTRL+C.
While Honggfuzz is running, you should see the corpus size increase and lines should keep appearing in the log.
The "Cov Update" value indicates how long it has been since the fuzzer found a new interesting test case.
If the fuzzer isn't finding new test cases or the speed is below 100, then something is probably wrong.

> [!NOTE]
> You can experiment a bit to see how different factors affect how long it takes Honggfuzz to find the crash.
> For example, you can try using less files in the seed corpus, or not using the dictionary by removing the `-w pdf.dict` arguments.
> Please don't leave the fuzzer running for more than a few minutes at a time during the meeting to avoid taking up all the server resources.
> Feel free to run it for longer after the meeting though.

## Triaging the Crash

Run `ls` after Honggfuzz finds a crash and you should see a file named something like `SIGSEGV.PC.57605a.STACK.1976259487.CODE.1.ADDR.7fff4d888ff8.INSTR.call___0xffffffffffe904c6.fuzz`.
This contains the test case that caused the crash, and you can run `pdftotext` on the file to verify that it crashes.
The file name might have special characters in it, so it should be surrounded by single quotes.
To avoid typing the whole thing, you can type the first few characters and press the Tab key which should auto-complete the rest.

There should also be a file named `HONGGFUZZ.REPORT.TXT`, and you can print it out using `cat`:

```sh
cat HONGGFUZZ.REPORT.TXT
```

Alternatively, you can read the file with VS Code, which you can open in your browser by running this command:

```sh
code tunnel
```

This file contains some details of the crash, including the backtrace which lists the function calls that lead to the crash.
You'll see a few lines repeating over and over again because the crash was due to infinite recursion.
If you were investigating a new bug that you just found, the next step would be to figure out the root cause using tools such as GDB.
This requires a lot more knowledge that we don't have time to cover and being familiar with the code that we're fuzzing, so we will stop here.

> [!NOTE]
> What information about the crash is contained in the file name of the test case?

> [!NOTE]
> What would happen if you tried to open the test case file in a PDF viewer?
