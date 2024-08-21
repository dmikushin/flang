# Use the base image for the specific LLVM branch
ARG LLVM_BRANCH=release_18x
FROM ghcr.io/flang-compiler/ubuntu-flang-${LLVM_BRANCH}:latest AS builder

ARG TARGET

# Set environment variables
ENV build_path=/home/github
ENV install_prefix=/home/github/usr/local

USER root

# Install necessary tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    cmake \
    make && \
    rm -rf /var/lib/apt/lists/*

USER github

# Clone the Flang repository
RUN mkdir -p ${build_path} && cd ${build_path} && \
    git clone https://github.com/flang-compiler/flang.git

# Build and install Flang & libpgmath
RUN cd ${build_path}/flang && \
    ./build-flang.sh -t ${TARGET} -p ${install_prefix} -n `nproc --ignore=1` -v -l /home/root/classic-flang-llvm-project/llvm

# Copy llvm-lit
RUN cd ${build_path}/flang && \
    cp /home/root/classic-flang-llvm-project/build/bin/llvm-lit build/flang/bin/.



FROM ubuntu:22.04

COPY --from=builder /home/github/usr/local /home/github/usr/local

RUN apt update && \
    apt --no-install-recommends install -y ca-certificates gpg wget

RUN test -f /usr/share/doc/kitware-archive-keyring/copyright || \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null

RUN apt update && \
    rm -rf /usr/share/keyrings/kitware-archive-keyring.gpg && \
    apt --no-install-recommends install -y cmake kitware-archive-keyring

RUN apt --no-install-recommends install -y fish && \
    chsh -s /usr/bin/fish root

RUN apt --no-install-recommends install -y make binutils libc6-dev libgcc-12-dev

ENV PATH=$PATH:/home/github/usr/local/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/github/usr/local/lib
