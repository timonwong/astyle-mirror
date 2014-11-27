# Make file for Clang compiler on Mac OS X
# The license.html file describes the conditions under which this software may be distributed.

# to test on Linux use "make  linux=1"

# list of source files
SRC = astyle_main.cpp \
      ASBeautifier.cpp \
      ASFormatter.cpp \
      ASEnhancer.cpp \
      ASLocalizer.cpp \
      ASResource.cpp

# source directories
vpath %.cpp ../../src
vpath %.h   ../../src

# NOTE for java compiles the environment variable $JAVA_HOME must be set
# example: export JAVA_HOME=/usr/lib/jvm/java-6-sun-1.6.0.00
ifndef JAVA_HOME
    JAVA_HOME = /usr/lib/jvm/default-java
endif

# set prefix if not defined on the command line
ifndef prefix
    prefix=/usr
endif
SYSCONF_PATH=$(prefix)/share/doc/astyle
# the path was changed in release 2.01
# SYSCONF_PATH_OLD may be removed at the appropriate time
SYSCONF_PATH_OLD=$(prefix)/share/astyle

# define macros
dylib = dylib
dynamiclib = -dynamiclib
bindir = bin
objdir = obj
ipath=$(prefix)/bin
CBASEFLAGS = -W -Wall -fno-rtti -fno-exceptions
UNIVFLAGS = -arch i386 -arch x86_64
JAVAINCS   = -I/System/Library/Frameworks/JavaVM.framework/Headers
CXX = clang++
INSTALL=install -o $(USER) -g wheel
# INSTALL=install -o 0 -g 0

# set debug directories for DEBUG=1 on the command line
ifdef DEBUG
    bindir = debug
    objdir = objd
endif

# for testing on linux
ifdef linux
    dylib = so
    dynamiclib = -shared
    JAVAINCS   = -I$(JAVA_HOME)/include
endif

##################################################

# define compile options for each build
# CFLAGS from the command line is added or defaults are used
ifdef CFLAGS
ifdef DEBUG
    CFLAGSas = -g $(CBASEFLAGS) $(CFLAGS)
else
    CFLAGSas = -DNDEBUG $(CBASEFLAGS) $(CFLAGS)
endif
else
ifdef DEBUG
    CFLAGSas = -g $(CBASEFLAGS)
else
    CFLAGSas = -DNDEBUG -O3 $(CBASEFLAGS)
endif
endif
CFLAGSs   = -DASTYLE_LIB -fPIC -fvisibility=hidden $(CFLAGSas)
CFLAGSa   = -DASTYLE_LIB $(CFLAGSas)
CFLAGSsj  = -DASTYLE_JNI -fPIC -fvisibility=hidden $(CFLAGSas) $(JAVAINCS)

# define link options
ifdef LDFLAGS
    LDFLAGSr = $(LDFLAGS)
    LDFLAGSd = $(LDFLAGS)
endif

# object files are built from the source list $(SRC)
# a suffix is added for each build
OBJ   = $(patsubst %.cpp,$(objdir)/%.o,$(SRC))
OBJs  = $(patsubst %.cpp,$(objdir)/%_s.o,$(SRC))
OBJa  = $(patsubst %.cpp,$(objdir)/%_a.o,$(SRC))
OBJsj  = $(patsubst %.cpp,$(objdir)/%_sj.o,$(SRC))

# define object file rule (with the suffix) for each build

# OBJ
$(objdir)/%.o:  %.cpp  astyle.h  astyle_main.h
	@ mkdir -p $(objdir)
	$(CXX) $(CFLAGSas) -c -o $@ $<

# OBJs
$(objdir)/%_s.o:  %.cpp  astyle.h
	@ mkdir -p $(objdir)
	$(CXX) $(CFLAGSs) $(UNIVFLAGS) -c -o $@ $<

# OBJa
$(objdir)/%_a.o:  %.cpp  astyle.h
	@ mkdir -p $(objdir)
	$(CXX) $(CFLAGSa) -c -o $@ $<

# OBJsj
$(objdir)/%_sj.o:  %.cpp  astyle.h
	@ mkdir -p $(objdir)
	$(CXX) $(CFLAGSsj) $(UNIVFLAGS) -c -o $@ $<

##################################################
# define build dependencies for each command

release:  astyle
astyle:  $(OBJ)
	@ mkdir -p $(bindir)
	$(CXX) $(LDFLAGSr) -o $(bindir)/$@ $^
	strip $(bindir)/$@
	@ echo

shared:  libastyle-2.06.$(dylib)
libastyle-2.06.$(dylib):  $(OBJs)
	@ mkdir -p $(bindir)
	$(CXX) $(dynamiclib) $(LDFLAGSr) $(UNIVFLAGS) -o $(bindir)/$@ $^
	@ echo

static:  libastyle.a
libastyle.a:  $(OBJa)
	@ mkdir -p $(bindir)
	ar crs $(bindir)/$@ $^
	@ echo

java:  libastyle-2.06j.$(dylib)
libastyle-2.06j.$(dylib):  $(OBJsj)
	@ mkdir -p $(bindir)
	$(CXX) $(dynamiclib) $(LDFLAGSr) $(UNIVFLAGS) -o $(bindir)/$@ $^
	@ echo

all:  release  static  shared

clean:
	rm -f $(objdir)/*.o $(bindir)/*astyle*

cleanobj:
	rm -f $(objdir)/*.o

install:
	$(INSTALL) -m 755 -d $(ipath)
	@$(INSTALL) -m 755 $(bindir)/astyle  $(ipath)

	@if [ -d $(SYSCONF_PATH)/html ]; then \
		rm -rf  $(SYSCONF_PATH)/html; \
	fi

	$(INSTALL) -m 755 -d $(SYSCONF_PATH)
	@mkdir -p $(SYSCONF_PATH)/html;
	@for files in ../../doc/*.html  ../../doc/*.css; \
	do \
		$(INSTALL)  -m 644  $$files  $(SYSCONF_PATH)/html; \
	done

	@if [ -d $(SYSCONF_PATH_OLD) ];  then \
		rm -rf $(SYSCONF_PATH_OLD); \
	fi

uninstall:
	rm -f $(ipath)/astyle
	rm -rf $(SYSCONF_PATH)
	@if [ -d $(SYSCONF_PATH_OLD) ];  then \
		rm -rf $(SYSCONF_PATH_OLD); \
	fi
