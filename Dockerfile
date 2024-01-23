FROM fedora

RUN dnf upgrade -y && dnf install -y honggfuzz gcc gcc-c++ libasan libubsan make cmake autoconf git gdb man unzip

WORKDIR /fuzz
