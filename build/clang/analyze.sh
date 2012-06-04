#!/bin/bash
# Run the Clang static analyzer during a compile.
# Support for analyzing C++ and Objective-C++ files is currently extremely limited.
# C++ analyzer support is at http://clang-analyzer.llvm.org/dev_cxx.html .
# C++11 support is at http://clang.llvm.org/cxx_status.html .
# Static analyser information is at http://clang-analyzer.llvm.org/scan-build.html

projdir=$HOME/Projects/AStyle/build/clang

# Must be run from the directory with the Clang Makefile.
# -v  is verbose output.
# -V  is view analysis results in a web browser.
# -o  is the target directory for HTML report files. 

make  clean
scan-build -v -v -v -V -o $projdir  make astyled
