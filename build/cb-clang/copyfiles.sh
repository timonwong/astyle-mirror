#!/bin/bash
# Copy gcc object files so the Clang compiler can find them.
# Needed with Clang 2.9.11. The problem is fixed in version 3.0.

projdir=$HOME/Projects/AStyle/build/cb-clang
objdir=/usr/lib/x86_64-linux-gnu

for v in  crt1.o  crti.o  crtn.o
do
	cp --preserve --verbose --force  $objdir/$v  $projdir
done
