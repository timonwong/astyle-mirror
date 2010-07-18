#!/bin/bash

# Set the environment variables prior to invoking the compiler.
# For Intel compiler release 11.1 and higher.
# The script iccvars.sh should be copied to /usr/sbin.
# Assumes the intel64 compiler. Needs to be changed for other  compilers.
# Instructions are in "getting_started_c.pdf" in the section 
#     "Starting the Compiler from the Command Line".

if [ -e  /usr/sbin/iccvars.sh ]; then
	# source  /usr/sbin/iccvars.sh  ia32
	# source  /usr/sbin/iccvars.sh  ia64
	source  /usr/sbin/iccvars.sh  intel64
fi

make $1 $2 $3 $4 $5 $6 $7 $8 $9
