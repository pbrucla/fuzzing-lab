# Week 2: Basic Honggfuzz Usage

[Honggfuzz](https://honggfuzz.dev) is a easy-to-use fuzzer developed by Google which has found [many vulnerabilities](https://github.com/google/honggfuzz#trophies).
We will be using it to rediscover an infinite recursion denial-of-service vulnerability in [Xpdf](https://www.xpdfreader.com).
**We recommend that you type out the commands in this exercise (except for URLs) instead of copying and pasting them.
This will help you remember things.**

This exercise is based on [Fuzzing101 Exercise 1](https://github.com/antonio-morales/Fuzzing101/tree/main/Exercise%201).

## Docker

### Installation

We will be using [Docker](https://www.docker.com) to provide a Linux environment for those of you running inferior operating systems.
If you don't have Docker installed, follow the [installation instructions](https://docs.docker.com/get-docker/) on the Docker website.
On Windows, you can also install Docker inside WSL.
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
