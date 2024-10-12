# Week 3: Coverage-Guided Fuzzing & Fuzzing Libraries

This week, we will be learning more about **coverage-guided fuzzing**, which is the main technique used in modern fuzzers.
Often times, when performing fuzzing, some memory corruption bugs **do not crash the program** making them harder to detect.
Using binary instrumentation, we can use tools like **sanitizers** to make it easier to detect these bugs and measure **code coverage**.
Often times, the programs we need to fuzz are not standalone executables, but **shared libraries** (especially in the case of larger projects).

This week, we will cover all of these topics by rediscovering a vulnerability in the [libexif](https://libexif.github.io/) library, which parses Exif image metadata.
A library can't be executed on its own, so we'll need to compile an executable program that uses the library (in this case, the [exif](https://github.com/libexif/exif) program).

> [!NOTE]
> This week's exercise will have less commands provided so you can get a chance to try and figure things out in preparation for the project!
> If you forgot how to run a command or need an explanation on a fuzzing concept, you can try searching for information online, running `man <command_name>`, or running a command with the `--help` option, or refer back to [last week's exercise](02-intro-to-fuzzing.md).
> Please ask for help if you're stuck, we're here to help!

## Fuzzing Libexif

In this exercise, we will rediscover a vulnerability in the [libexif](https://libexif.github.io/) library, which parses Exif image metadata.
A library can't be executed on its own, so we'll need to compile an executable program that uses the library.
One executable that we can use is the [exif](https://github.com/libexif/exif) tool provided by the libexif project.
In later weeks, we will show how to write your own executable to achieve much better performance.

## Building libexif

On the server, create a new directory called `libexif/` in your home directory and change directory into it. This directory will be used to store the source code, build files for libexif, and other related files we will need for this exercise.

```sh
mkdir libexif
cd libexif
```

Once inside the directory, download libexif, extract the archive, and then move into the resulting directory.

```sh
curl -LO https://github.com/libexif/libexif/archive/refs/tags/libexif-0_6_14-release.tar.gz
gzip -d libexif-0_6_14-release.tar.gz
cd libexif-0_6_14-release/
```

Unlike xpdf from last week, libexif doesn't include a `configure` script inside its repository, so we have to generate one by using a program called `autoconf`. You can run `autoreconf --help` to see what the options do.

```sh
autoreconf -fvi
```

Next, here is the first command you will try figuring out yourself.
Your goal is to build and install libexif.

> [!NOTE]
> What is the command you need to generate the build files for libexif?
> Remember to use the Honggfuzz compiler and set the install prefix.
> You will also need to add the `--enable-shared=no` option to disable the generation of shared library files.
> Hint: It uses the `configure` script.

> [!NOTE]
> What is the command you need to run to build libexif?

> [!NOTE]
> What is the command you need to run to install libexif?

After you have successfully built and installed libexif, you should see a few files created inside the `$HOME/libexif/install/lib/` directory.

## Building exif

After we build libexif, we now need to build the `exif` program that uses the libexif library.
This will act as a target program for our fuzzer so we can find vulnerabilities in the library.

Navigate back to your `libexif/` directory and download the exif source code. Make sure to extract the archive and move into the resulting directory.

```sh
cd ..
curl -LO https://github.com/libexif/exif/archive/refs/tags/exif-0_6_15-release.tar.gz
tar -xzvf exif-0_6_15-release.tar.gz
cd exif-exif-0_6_15-release/
```

Now, you will need to run the `configure` script to generate the build files for the `exif` program.
You will need to add an option to the `configure` script to help it find the libexif library that we just installed.

> [!NOTE]
> What is the command you need to run to generate the build files for the `exif` program?
> You will need to add `PKG_CONFIG_PATH=install/lib/pkgconfig` to the end of the command.
> Remember to use the Honggfuzz compiler and set the install prefix.

> [!NOTE]
> What is the command you need to run to build the `exif` program?

> [!NOTE]
> What is the command you need to run to install the `exif` program?

After you have successfully built and installed the `exif` program, return to the `libexif/` directory and run the `exif` program.
You should a help message printed out by the following command.

```sh
install/bin/exif
```

## Fuzzing exif

For our seed corpus, download some samples of images with Exif metadata and extract them.

```sh
curl -LO https://github.com/ianare/exif-samples/archive/refs/heads/master.zip
unzip master.zip
```

Try running `exif` on one of the images in the resulting directory.
It should print out information about the image.

```sh
install/bin/exif exif-samples-master/jpg/Canon_40D.jpg
```

Now run Honggfuzz using the files in the `exif-samples-master/jpg` directory as the seed corpus.
The only argument to the target program should be the input file generated by the fuzzer.
You should get a crash after a while, but it may take up to half an hour.

> [!NOTE]
> What is the Honggfuzz command you need to run to fuzz the `exif` program?
> If you don't remember how to run Honggfuzz, check out [last week's exercise](02-intro-to-fuzzing.md) or ask for help.

After you get the crash, you can examine `HONGGFUZZ.REPORT.TXT` and try to understand what caused the crash.
See if you can try and replicate the crash using the `exif` program and test case found by Honggfuzz.

> [!NOTE]
> What is the command you used to replicate the crash?

## Acknowledgements
This exercise is based on [Fuzzing101 Exercise 2](https://github.com/antonio-morales/Fuzzing101/tree/main/Exercise%202).
