#!/bin/bash
# Unnstall the astyle file and documentation.
# For testing change the "prefix" variable and "sudo" is not needed.
# NOTE: Use ~, not $HOME.  HOME is not defined in SciTE.

# prefix may be changed for testing
prefix=/usr
#prefix=/private/tmp/AStyle.dst/usr

NORMAL="[0;39m"
# CYAN, BOLD: information
CYAN="[1;36m"
# YELLOW; system message
YELLOW="[0;33m"
# WHITE, BOLD; error message
WHITE="[1;37m"
# RED, BOLD: failure message
RED="[1;31m"

ipath=$prefix/bin
SYSCONF_PATH=$prefix/share/doc/astyle
# the path was changed in release 2.01
# SYSCONF_PATH_OLD may be removed at the appropriate time
SYSCONF_PATH_OLD=$prefix/share/astyle

# define $result variable here
result=:
unset result

# error handler function
check_error () {
	if [ $result -ne 0 ] ; then
		echo -n $WHITE
		echo "Error $result returned from function"
		echo "Did you use 'sudo'?"
		echo $RED
		echo "** INSTALL FAILED **"
		echo $NORMAL
		exit 1
	fi
	unset result
}

# must uninstall from this path
if [ ! -f uninstall.sh ]; then
	echo -n $WHITE
	echo "Cannot uninstall from this path"
	echo "Change to the directory containing uninstall.sh"
	#read -sn1 -p "Press any key to end . . ."
	echo; echo -n $NORMAL
	exit 1
fi

# uninstall astyle
echo $CYAN
echo "Unnstalling astyle from $ipath"
echo -n $YELLOW
rm -f $ipath/astyle
result=$?;	check_error

# uninstall documentation
echo -n $CYAN
echo "Unnstalling documentation from $SYSCONF_PATH"
echo -n $YELLOW
if [ -d $SYSCONF_PATH ]; then
	rm -rf  $SYSCONF_PATH
	result=$?;	check_error
fi

#remove old documentation
if [ -d $SYSCONF_PATH_OLD ];  then
	rm -rf $SYSCONF_PATH_OLD
	result=$?;	check_error
fi

echo $WHITE
echo "** INSTALL SUCCEEDED **"

echo; echo -n $NORMAL
