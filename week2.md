# Week 2: Basic Honggfuzz Usage

[Honggfuzz](https://honggfuzz.dev) is a easy-to-use fuzzer developed by Google which has found [many vulnerabilities](https://github.com/google/honggfuzz#trophies).
We will be using it to rediscover an infinite recursion denial-of-service vulnerability in [Xpdf](https://www.xpdfreader.com).

**We recommend that you type out the commands in this exercise (except for URLs) instead of copying and pasting them.
This will help you remember things.**
You should try to understand what each command line argument does rather than memorize the whole command.
In later weeks we might not tell you the exact commands that you should run and you'll have to figure them out yourself.

This exercise is based on [Fuzzing101 Exercise 1](https://github.com/antonio-morales/Fuzzing101/tree/main/Exercise%201).

## Docker

### Installation

We will be using [Docker](https://www.docker.com) to provide a Linux environment for those of you running inferior operating systems.
If you don't have Docker installed, follow the [installation instructions](https://docs.docker.com/get-docker/) on the Docker website.
On Windows, use the WSL backend instead of the Hyper-V backend.
If you have Linux already, you can try fuzzing without Docker but you may have to build and install Honggfuzz manually.

### Building the image

Once you have Docker installed, clone this repository (`git clone 'https://github.com/pbrucla/fuzzing-lab.git'` if you have Git) or place our [Dockerfile](https://github.com/pbrucla/fuzzing-lab/blob/main/Dockerfile) inside a new empty directory.
Make sure the file name is `Dockerfile` with the same capitalization and no extension.
Note that Windows may hide file name extensions.
This file tells Docker how to build a Docker *image*, which is a template used to spawn Docker *containers*.
Each container is an isolated Linux environment with its own file system.

The Dockerfile looks like this:

```dockerfile
FROM fedora

RUN dnf upgrade -y && dnf install -y honggfuzz gcc gcc-c++ libasan libubsan make cmake autoconf git

WORKDIR /fuzz
```

The first line tells Docker to start from an image containing [Fedora Linux](https://fedoraproject.org).
We're using the Fedora Linux distribution because I like it, and it has Honggfuzz packaged.
The next command updates the packages in the image, then installs Honggfuzz and some other tools that we'll need.
The `WORKDIR` command sets the working directory to `/fuzz`.

Inside the directory containing the Dockerfile, run `docker build -t fuzz .`.
Note the period at the end of the command.
You might have to prefix all Docker commands with `sudo` like `sudo docker build -t fuzz .` depending on how your Docker is set up.
This will build the image following the Dockerfile and may take a few minutes.
The `-t fuzz` option assigns the name `fuzz` to the resulting image, which will be stored inside a directory managed by Docker.
You can list the Docker images that you have on your system with `docker images` and delete them with `docker rmi <image>` where `<image>` is the image name or ID.

### Running a container

Run `docker run -it --name xpdf fuzz` to create a new Docker container using our `fuzz` image. `-it` is short for `-i -t`, which are two flags that set up input and output so that we can use the container interactively.
The `--name fuzz_xpdf` option assigns the name `fuzz_xpdf` to the container so that we can easily reference it later.
You should now have a Linux shell inside the container, similar to what you have on SEASnet.
You can exit the container by typing the `exit` command or pressing CTRL-D on a new line.
To reenter the container later, run `docker start -ai fuzz_xpdf`.
The `-ai` flags are similar to the `-it` flags we used when creating the container and allow us to run the container interactively.
You can list the containers on your system with `docker ps -a`, where the `-a` flag makes Docker show all containers, not just ones that are running.
To delete a container, run `docker rm <container>`.
**This will permanently delete the container without asking for confirmation.**

## Fuzzing Xpdf

### Instrumentation

To fuzz effectively, the fuzzer needs a way to monitor the execution of the target program so that it knows which inputs generate interesting new behavior.
We will compile the target with a special compiler which inserts instrumentation code that allows Honggfuzz to track code coverage.
Honggfuzz can also monitor the target using hardware features on some CPUs or the QEMU emulator.

Inside the Docker container, download the Xpdf source code using the `curl` utiliy by running `curl -LO 'https://dl.xpdfreader.com/old/xpdf-3.02.tar.gz'`.
The `-L` flag tells curl to follow redirects, and the `-O` flag makes curl automatically determine the output file name.
The downloaded file is a tar archive compressed using gzip.
To extract it, run `tar -xvzf xpdf-3.02.tar.gz`.
Here, `x` means extract, `v` means verbose (print out file names while extracting), `z` means the file is compressed with gzip, and `f` means read from the file named in the next argument instead of stdin.
`cd` into the resulting `xpdf-3.02` directory.

Now we will build Xpdf using the GNU build system.
First, run `CC=hfuzz-clang CXX=hfuzz-clang++ ./configure --prefix=/fuzz/install` to generate a Makefile containing the commands that need to be executed in order to build Xpdf.
`CC=hfuzz-clang CXX=hfuzz-clang++` sets the C and C++ compilers to the Honggfuzz compilers which will instrument the program.
The `--prefix` option sets the directory where Xpdf will be installed after it is built.
Next, run `make -j <num_cores>` where `<num_cores>` is the number of CPU cores on your computer, which you can determine by running the `nproc` command.
This will compile Xpdf by executing the commands in the Makefile.
The `-j` option tells Make how many jobs to run in parallel.
Finally, run `make install`.
This will install Xpdf into the directory we specified earlier.
Go back to our `fuzz `directory with `cd ..`.
If you run `ls install/bin` now you should see several executables including `pdftotext`, which is the one that we will fuzz.

### Initial corpus

To help Honggfuzz find interesting inputs, we will give it a few small examples of valid PDF files.
Create a directory to hold these files and download some sample PDFs:

```sh
mkdir pdf_examples
cd pdf_examples
curl -LO 'https://github.com/mozilla/pdf.js-sample-files/raw/master/helloworld.pdf'
curl -LO 'http://www.africau.edu/images/default/sample.pdf'
curl -LO 'https://www.melbpc.org.au/wp-content/uploads/2017/10/small-example-pdf-file.pdf'
cd ..
```

You can try running `pdftotext` on one of these files like this: `install/bin/pdftotext pdf_examples/helloworld.pdf -`.
`pdftotext` converts PDF files to plain text.
The first argument is the input PDF file, and the second argument is the output text file (`-` means output to stdout).
It should output `Hello, world!` followed by a few blank lines.

### Dictionary

Another way that we can help Honggfuzz is use a dictionary, which is a list of common byte sequences for the file format that we're fuzzing.
Honggfuzz will try inserting these sequences into the input data and it will have a higher change of creating partially-valid files that trigger new behavior in our target.
We'll use a PDF dictionary from AFL++, another popular fuzzer.
Download it with this command:

```sh
curl -LO 'https://github.com/AFLplusplus/AFLplusplus/raw/stable/dictionaries/pdf.dict'
```

### Fuzzing

Here's the fun part!
To start fuzzing, run `honggfuzz -i pdf_examples -o corpus -w pdf.dict -- install/bin/pdftotext ___FILE___ /dev/null`.
We give Honggfuzz the `pdf_examples` directory as the initial input corpus and tell it to store new interesting inputs in the `corpus` directory.
We also provide the dictionary with `-w pdf.dict`.
After the `--`, we specify the program to be fuzzed along with its arguments.
`___FILE___` is a placeholder which Honggfuzz will replace with the name of the input file, and we make the program output to `/dev/null`, which is a special file that discards anything written to it.

You should now see a fancy status panel.
Depending on your luck and how powerful your computer is, it may take anywhere from a few seconds to tens of minutes for Honggfuzz to find a crash.
Once Honggfuzz finds a crash, you can stop the fuzzing with CTRL-C.
You can also use the `--exit_upon_crash` flag to have Honggfuzz automatically stop when it finds a crash.
You should see the corpus size increase and lines should keep appearing in the log.
The "Cov Update" value indicates how long it has been since the fuzzer found a new interesting input.
If the fuzzer isn't finding new inputs or the speed is below 100, then something is probably wrong.

Now run `ls` and you should see a file named something like `SIGSEGV.PC.57605a.STACK.1976259487.CODE.1.ADDR.7fff4d888ff8.INSTR.call___0xffffffffffe904c6.fuzz`.
This contains the input that caused the crash.
There should also be a file named `HONGGFUZZ.REPORT.TXT`, and you can print it out by running `cat HONGGFUZZ.REPORT.TXT`.
This file contains some details of the crash, including the backtrace which is the list of function calls that lead to the crash.
You'll see a few lines repeating over and over again because the crash was due to infinite recursion.
If you were investigating a new bug that you just found, the next step would be to figure out the root cause using tools like GDB.
That requires a lot more knowledge that we don't have time to cover and being familiar with the code that we're fuzzing, so we will stop here.
