#!/bin/bash

# Before running "make" the COMPILER environment variables must be set.
# To set the environment variables "source" the compiler environment script:
#     source compilervars.sh  [ ia32 | intel64 ]
# Refer to the install instructions for details.

# This executes the make with a temporary fix for Ubuntu based systems.
# The compile options must include -I/usr/include/x86_64-linux-gnu/c++/4.8.
# This is done by setting the __INTEL_POST_CFLAGS environment variable.

cd ~/Projects/AStyle/build/intel
source /opt/intel/bin/compilervars.sh  intel64
make __INTEL_POST_CFLAGS=-I/usr/include/x86_64-linux-gnu/c++/4.8  all
make __INTEL_POST_CFLAGS=-I/usr/include/x86_64-linux-gnu/c++/4.8  javaall

read -sn1 -p "Press any key to end . . ."

