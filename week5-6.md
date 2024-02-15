# Week 5: Fuzzing For New Vulnerabilities

From now on, we will be pivoting towards fuzzing various open-source projects to try to find new vulnerabilities.
Our goal is for you to be able to fuzz new projects without help from us.
We have chosen projects that we think are most likely to have vulnerabilities which can be found by fuzzing, but whether you find a vulnerability still depends a lot on luck so don't feel too disappointed if you don't get a crash.

**I want to emphasize again that you should avoid copying and pasting commands that we give you.**
The point of this lab is to help you learn how to fuzz, and you will not learn anything by copying and pasting commands without understanding them, just like how you're can't learn to program by copying and pasting other people's code.
Copying the commands in the instructions from previous weeks will not be enough for completing the rest of this lab.
If you don't know how to do something, try reading documentation or searching online.
This is arguably one of the most important skills in CS.

## Fuzzing server

We have set up a server so that you can fuzz for long periods of time without keeping your computer running and draining the battery.
It also makes it easier to collaborate with other people.

### SSH

You will be able to connect to the server using SSH, similar to how you log into the SEASnet servers.
If you're on Windows, go to **Settings**, select **System**, then select **Optional Features** and install **OpenSSH Client**.
The SSH client should already be installed on macOS.

We will be using SSH keys instead of passwords for authentication.
If you already have SSH keys, you can skip the next couple of steps.
To generate an SSH key, run `ssh-keygen -t ed25519` in a terminal (outside of WSL if you're on Windows).
`-t ed25519` sets the key type to Ed25519, a modern digital signature algorithm that is better than RSA.
When prompted for the location where the key will be saved, choose the default.
Your public key will be stored in a file named `id_ed25519.pub` and your private key will be in `id_ed25519`.
Both files will be your `.ssh` folder.
Send your **public** key to us so that we can give you access to the server.
The private key is used to prove that you own the public key and you should keep it secret.

Think of a username for your team and sent it to us.
If you're working with other people, you will use the same user on the server so that you can easily share access to the files.
Once we have added your key to the server, you can login by running `ssh username@fuzz.cerpfy.net`.

### VS Code

If you don't use a terminal text editor like Vim or Em*cs, you can use VS Code to edit files on the server.
Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension, then run the **Remote-SSH: Connect to Host** command.
See the [documentation](https://code.visualstudio.com/docs/remote/ssh) for more details.

### Installing packages

You do not have access to `sudo` on the server, so ask us if you need to install any packages.

## Fuzzing a new project

### Target list

We have compiled a list of potential targets for you to fuzz:

 - [libical](https://github.com/libical/libical)
 - [yaml-cpp](https://github.com/jbeder/yaml-cpp)
 - [Rapid YAML](https://github.com/biojppm/rapidyaml)
 - [libfyaml](https://github.com/pantoniou/libfyaml)
 - [cxml](https://github.com/ziord/cxml)
 - [xml.c](https://github.com/ooxi/xml.c)
 - [tomlc99](https://github.com/cktan/tomlc99)
 - [Ctoml](https://github.com/evilncrazy/ctoml)
 - [libwbxml](https://github.com/libwbxml/libwbxml)
 - [NanoSVG](https://github.com/memononen/nanosvg)
 - [TinyXML-2](https://github.com/leethomason/tinyxml2)

These are all parsers for file formats like YAML, TOML, and XML.
We chose these projects because they are easy to fuzz and appear to not have been fuzzed much.
Pick one that looks interesting to you.
If you don't find a crash, you can move on to another target.

### Building the target

In order to fuzz a project, you first have to compile it with the Honggfuzz compiler.
The steps to do this might be slightly different for each project since C/C++ build systems are such a mess.
Open-source projects commonly have build instructions in the README file or a file named INSTALL.
**You will have to modify those commands in order to build with the Honggfuzz compiler, set the installation directory, etc.**

### AddressSanitizer

We look for crashes when fuzzing, but not all bugs reliably cause a crash in C/C++.
One way to detect more bugs is to use sanitizers like [AddressSanitizer](https://github.com/google/sanitizers/wiki/AddressSanitizer).
When you compile with AddressSanitizer, the compiler inserts code that automatically check for things like out-of-bounds array accesses.
This helps us detect more vulnerabilities at the cost of making things slower.
To use AddressSanitizer, we need to set the `-fsanitize=address` flag when compiling.
This can be done setting the `CFLAGS` and `CXXFLAGS` envionment variables when running `configure` or CMake, similar to how we set the compiler using the `CC` and `CXX` envionment variables.

### Writing a harness

You will need to write a harness that takes input from the fuzzer and calls a function in the target library with the input.
Read the documentation for your target project and find a function that parses a sequence of arbitrary bytes.
See if there are example programs that show how to use the library.
When you write your harness, make sure that you're using the library correctly.
If the function expects a null-terminated string, you should make sure that the input is null-terminated.
Make sure to properly free things returned by the function if necessary.
You don't want to have crashes caused by a broken harness instead of a bug in the target.

### Seed corpus

For your seed corpus, you want a set of input files that test various parts of the target.
The files should be small so that they are processed quickly.
Some projects might have some test files inside their repositories and they generally make good seed corpuses.
For example, [libyaml](https://github.com/yaml/libyaml) has a few test cases in their [`examples` directory](https://github.com/yaml/libyaml/tree/master/examples).
Be sure to avoid large test cases used for benchmarking like these [tests from Rapid YAML](https://github.com/biojppm/rapidyaml/tree/master/bm/cases).
Also make sure that your seed corpus directory only contains the actual test files and not any other files like the programs used to run the tests.
If your project doesn't include test cases, you can search online for test suites.

Note that for the [YAML Test Suite](https://github.com/yaml/yaml-test-suite), the YAML files in the `src` directory aren't the actual test files.
The test data is contained in those files, but they have to be extracted with a script.
The format is also really annoying for us since each test file is in a separate directory with several other files, so I did some shell scripting to copy them all into one directory.
They're in `~alex/yaml-tests` on the server if you want to use them.

### Dictionaries

Using a dictionary might help the fuzzer increase coverage.
You can try searching for a fuzzing dictionary online.
Here's a [YAML dictionary](https://github.com/google/fuzzing/blob/master/dictionaries/yaml.dict) from [Google's fuzzing repo](https://github.com/google/fuzzing).

### Leaving the fuzzer running

By default, your processes will be stopped when you disconnect from the server.
You can use [tmux](https://github.com/tmux/tmux) to keep your fuzzer running.
Before you start fuzzing, run `tmux` to start a new tmux session.
This will start a new shell which you can then detach from by pressing `C-b d` (hold CTRL, press `b`, release both keys, then press `d`).
After detaching from the tmux session, you can disconnect from the server and the fuzzer will keep running.
To reattach to the tmux session later, run `tmux attach`.
Note that tmux will slightly change scrolling and text selection.

## Fuzzing resources

Here are some online resources that may be helpful:

 - [Fuzzing101](https://github.com/antonio-morales/Fuzzing101): Hands-on fuzzing tutorial which some of our exercises are based on.
 - [Google fuzzing repo](https://github.com/google/fuzzing): Tutorial for libFuzzer, some general tips, and dictionaries for common formats.
 - [Trail of Bits Testing Handbook](https://appsec.guide/docs/fuzzing/): Good introduction to fuzzing.
 - [AFL++ docs](https://aflplus.plus/): Documentation for another popular fuzzer.
 - [The Fuzzing Book](https://www.fuzzingbook.org/): Huge, extremely in-depth fuzzing textbook.
