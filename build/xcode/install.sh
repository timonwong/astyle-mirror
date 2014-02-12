#!/bin/bash
# Install the AStyle documentation.
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
# $USER will be root when sudo is used
INSTALL="install -o $USER -g wheel"

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


# must install from this path
if [ ! -f install.sh ]; then
	echo -n $WHITE
	echo "Cannot install from this path"
	echo "Change to the directory containing install.sh"
	echo; echo -n $NORMAL
	exit 1
fi

# remove previous documentaion
echo $CYAN
echo "Installing documentation to $SYSCONF_PATH"
echo -n $YELLOW
if [ -d $SYSCONF_PATH/html ]; then
	rm -rf  $SYSCONF_PATH/html
	result=$?;	check_error
fi
# create documentaion install directory
if [ ! -d $SYSCONF_PATH/html ]; then
	$INSTALL -m 755 -d $SYSCONF_PATH/html
	result=$?;	check_error
fi
# copy documentaion
for files in ../../doc/*.html  ../../doc/*.css
do
	$INSTALL  -m 644  $files  $SYSCONF_PATH/html
	result=$?;	check_error
done

# remove old documentation
if [ -d $SYSCONF_PATH_OLD ];  then
	rm -rf $SYSCONF_PATH_OLD
	result=$?;	check_error
fi

echo $WHITE
echo "** INSTALL SUCCEEDED **"

# has astyle been installed?
if [ ! -f $ipath/astyle ]; then
	echo $WHITE
	echo "The astyle executable has not been installed"
	echo "Use xcodebuild to install astyle"
fi

echo; echo -n $NORMAL
