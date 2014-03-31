#!/bin/bash

# This executes CodeBlocks with a temporary fix for Ubuntu based systems.

# This fix is not necessary for 2013_sp1.2.144 (2013 SP1 Update 2) and higher.

# This fix is for release 2013-sp1.1.106, testing for AStyle 2.05.
#     It is a temporary compiler bug work-around, from
#     http://software.intel.com/en-us/forums/topic/475786.
#     The compile options must include -I/usr/include/x86_64-linux-gnu/c++/4.8.
#     This is done by setting the __INTEL_POST_CFLAGS environment variable.

export __INTEL_POST_CFLAGS=-I/usr/include/x86_64-linux-gnu/c++/4.8
codeblocks  "$HOME/Projects/AStyle/build/cb-intel/Intel AStyle.workspace"
