FROM ubuntu:18.04
COPY . /arm_adb

ENV DEBIAN_FRONTEND noninteractive

# Build packages
RUN apt-get update && apt-get install -y \
  git wget unzip \
  build-essential \
  libtool \
  automake \
  linux-libc-dev-armhf-cross libc6-armhf-cross libc6-dev-armhf-cross \
  linux-libc-dev-arm64-cross libc6-arm64-cross libc6-dev-arm64-cross \
  python

# Toolchain
RUN mkdir /toolchains && \
    cd /toolchains && \
    wget --quiet https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz && \
    wget --quiet https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz && \
    tar xfJp gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz && \
    tar xfJp gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz 
RUN rm /toolchains/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz \
    /toolchains/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
ENV PATH /toolchains/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf/bin:$PATH
RUN cd /

# Google Toolchain
RUN cd /toolchains && \
    wget --quiet http://dl.google.com/android/repository/android-ndk-r13b-linux-x86_64.zip && \
    unzip android-ndk-r13b-linux-x86_64.zip && \
    mv android-ndk-r13b /usr/local/android-ndk && \
    rm android-ndk-r13b-linux-x86_64.zip 
ENV PATH $PATH:/usr/local/android-ndk:/toolchains/android-linux-armhf/bin:/toolchains/android-linux-arm64/bin
RUN cd /
RUN /usr/local/android-ndk/build/tools/make-standalone-toolchain.sh --arch=arm --platform=android-21 --install-dir=/toolchains/android-linux-armhf --toolchain=arm-linux-androideabi-4.9
RUN /usr/local/android-ndk/build/tools/make-standalone-toolchain.sh --arch=arm64 --platform=android-21 --install-dir=/toolchains/android-linux-arm64 --toolchain=aarch64-linux-android-4.9

# OpenSSL for ARM
RUN mkdir openssl && \
    cd /openssl && \
    git clone https://github.com/Kr0n0/openssl-1.0.2l.git && \
    cd openssl-1.0.2l/ && \
    ./Configure --prefix=/out/openssl no-shared os/compiler:arm-linux-gnueabihf-gcc && \
    make && make install && \
    cd /

# ADB for ARM
# NOTA : Cambiar el archivo Makefile para compilar en estatico
# >         $(LIBTOOLFLAGS) --mode=link $(CXXLD) $(adb_CXXFLAGS) \
# <         $(LIBTOOLFLAGS) --mode=link $(CXXLD) -all-static $(adb_CXXFLAGS) \
RUN cd /arm_adb && \
    autoreconf -v && \
    LDFLAGS='-static' ./configure --host=arm-linux-gnueabihf --includedir=/out/openssl/include --libdir=/out/openssl/lib --enable-static --prefix=/out && \
    make && make install && \ 
    cd /
