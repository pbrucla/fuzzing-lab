# Week 3: Fuzzing Libraries

This activity will give you more practice with the basic concepts that we've learned so far.
You will also learn how to compile your target with AddressSanitizer, which can help catch bugs that don't immediately cause a crash.

The vulnerability that we will be reproducing is in the [libexif](https://libexif.github.io/) library, which parses Exif image metadata.
A library can't be executed on its own, so we will also compile the [exif](https://github.com/libexif/exif) program which uses libexif.

> [!NOTE]
> This week's activity will have less commands provided so you can get a chance to try and figure things out yourself in preparation for the project!
> If you forgot how to run a command or need an explanation of a fuzzing concept, you can try searching for information online, running `man <command_name>`, running a command with the `--help` option, or refering back to [last week's activity](02-intro-to-fuzzing.md).
> Please ask for help if you're stuck, we're here to help!

## Enabling AddressSanitizer

As we've explained, AddressSanitizer can help us catch more bugs while fuzzing, at the cost of making the target slower.
To enable it, set the `HFUZZ_CC_ASAN` environment variable like this:

```sh
export HFUZZ_CC_ASAN=1
```

This tells the Honggfuzz compiler to compile programs with AddressSanitizer.
The environment variable is a property of your current shell session, so it will be gone when you close your terminal or log out of the server.
Setting the environment variable in one terminal also won't affect other terminals that you have open.
If you're not sure whether you have the environment variable set in your current terminal, you can run this command:

```sh
echo "$HFUZZ_CC_ASAN"
```

This will output `1` if it's set and nothing otherwise.

The memory leak detector in AddressSanitizer might report some leaks in `libexif` that aren't relevant to this activity, so disable it by running the following command:

```sh
export ASAN_OPTIONS=detect_leaks=0
```

## Building libexif

On the server, create a new directory called `libexif` in your home directory and move into it.
This is where we will store the files for this activity.
If you need a refresher on how to do this, see [last week's slides](https://l.acmcyber.com/fuzzing-lab-1).

Use `curl` to download libexif from <https://github.com/libexif/libexif/archive/refs/tags/libexif-0_6_14-release.tar.gz>, extract the archive with `tar`, and move into the resulting directory.

Unlike Xpdf from last week, libexif doesn't include a `configure` script inside its repository, so we have to generate one using a program called `autoreconf`:

```sh
autoreconf -fvi
```

You don't need to understand the options for this command, but if you're interested you can run `man autoreconf`.

As discussed in the presentation, we always want to use static linking instead of dynamic linking for the library that we're fuzzing.
Note that dynamically linked libraries are also known as shared libraries.
Run the following command to see the available options for the `configure` script:

```sh
./configure --help
```

Find the option to disable building shared libraries.
Hint: The option has `shared` in its name.

Run the `configure` script with the appropriate arguments, including the option that you just found.
Remember to set `CC` and `CXX` to the Honggfuzz compilers, and use the `--prefix` option to set the appropriate installation directory.
You can refer to last week's activity, but if you copy and paste the commands without changing anything it will not work.
Use `make` to compile libexif and install it to the directory you specified.

Go back to your `libexif` directory (the one you created at the very beginning of this activity).
List the contents of `install/lib`, and you should see the following:

```
libexif.a  libexif.la  pkgconfig
```

## Building exif

After we build libexif, we now need to build the `exif` program that uses the libexif library.
This will act as a target program for our fuzzer so we can find vulnerabilities in the library.

Download the exif source code from <https://github.com/libexif/exif/archive/refs/tags/exif-0_6_15-release.tar.gz>, extract the archive, and move into the resulting directory.
Build and install exif using the same commands that you used for libexif, except that when you run the `configure` script, append `PKG_CONFIG_PATH="$HOME/libexif/install/lib/pkgconfig"` to the end of the command.
This tells the build system where to find the libexif library that you built and installed earlier.

Return to the `libexif` directory and run the `exif` program that you just built:

```sh
install/bin/exif
```

This should print a help message.

## Fuzzing exif

For our seed corpus, download some samples of images with Exif metadata and extract them:

```sh
curl -LO https://github.com/ianare/exif-samples/archive/refs/heads/master.zip
unzip master.zip
```

Try running `exif` on one of the images in the resulting directory:

```sh
install/bin/exif exif-samples-master/jpg/Canon_40D.jpg
```

This should print out some information about the image.

Now run Honggfuzz using the files in the `exif-samples-master/jpg` directory as the seed corpus.
The only argument to the target program should be the input file generated by the fuzzer.

Hint: You should set the `-i`, `-o`, and `--exit_upon_crash` options.
You don't need `-w` since we're not using a dictionary for this activity.
For the options that take a value, it's up to you to figure out what value you need to pass.
Recall that after the Honggfuzz options, you should put `--` followed by the target program and its arguments.
If you don't remember what the Honggfuzz options do, run `honggfuzz --help`.
You can also look at [last week's activity](02-intro-to-fuzzing.md), but copying the whole command won't be sufficient here.

> [!NOTE]
> Honggfuzz's `___FILE___` placeholder has **three** underscores on each side (commonly mistaken for two).

After you get the crash, you can examine `HONGGFUZZ.REPORT.TXT` and try to understand what caused the crash.
Replicate the crash using the `exif` program and the test case found by Honggfuzz and you should see some colorful output from AddressSanitizer when it detects the bug.

> [!NOTE]
> The AddressSanitizer report contains a lot of useful information that can be used to diagnose the bug.
> Try reading the output and see if you can figure out what type of vulnerability AddressSanitizer detected.

## Acknowledgements

This activity is based on [Fuzzing101 Exercise 2](https://github.com/antonio-morales/Fuzzing101/tree/main/Exercise%202).
