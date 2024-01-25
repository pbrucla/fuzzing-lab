FROM fedora

RUN dnf upgrade -y && \
	dnf install -y \
		autoconf \
		cmake \
		gcc \
		gcc-c++ \
		gdb \
		git \
		honggfuzz \
		lcov \
		libasan \
		libubsan \
		make \
		man \
		unzip \
	;

WORKDIR /fuzz
