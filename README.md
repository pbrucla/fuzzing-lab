# Fuzzing Lab

This is the repository for UCLA ACM Cyber's Introduction to Fuzzing Lab.
Some parts were inspired by [Fuzzing101](https://github.com/antonio-morales/Fuzzing101).

## Docker

To facilitate easy usage of these tools with everyone's computers we will be using docker (allows you to run a reproducible linux on any operating system).

Our environment differs from the Fuzzing101 tutorial in two important ways:
1. we use honggfuzz instead of afl (honggfuzz is easier to use)
2. we use fedora instead of ubuntu - apt will not work, use dnf instead (alex really likes fedora and honggfuzz was not in ubuntu packages)

Mac Installation: ...
Windows Installation: ...

Once you have docker installed, running following commands in this repo directory will help you

```sh
# below command builds the docker image
docker build -t fuzz .

# below command runs the docker image
docker run --rm -it -v `pwd`:/fuzz fuzz

# below command kills your docker image if you want it assasinated mercilessly
docker kill `docker ps | grep fuzz | awk '{print($1)}'`

# give yourself permission over files created from docker
sudo chown -R `whoami` .
```

The instructions will synchronize the contents of this repo you have checked out with the directory you are in Docker. You may edit files locally and see them reflected in the docker and vice versa.

It is recommended to make a folder `work` where you do all your `curl`ing and `tar`ing so that you can always re-visit those parts without having to re-download files.

# License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
