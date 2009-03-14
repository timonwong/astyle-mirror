$! See bottom of file for comments.
$	old_verify = f$verify (0)
$	say := write sys$output
$	status = 1
$	cxx_avail = 0
$	make_avail = 0
$	use_mmk = 0
$	debug_flag = 0
$	lib_flag = 0
$	jni_flag = 0
$	test_no_cxx = 0
$	test_no_mms = 0
$	test_no_lib = 0
$
$	p2_len = f$length (p2)
$	if p2_len .gt. 0
$	then
$	    p2 = f$edit (p2, "upcase")
$	    test_no_cxx = f$locate ("C", p2) .lt. p2_len
$	    test_no_mms = f$locate ("M", p2) .lt. p2_len
$	    test_no_lib = f$locate ("L", p2) .lt. p2_len
$	endif
$
$! Let's test to see if we have the C++ compiler.
$!
$	say "Testing the build environment..."
$	set noon
$	define/nolog sys$output nl:
$	define/nolog sys$error nl:
$	cxx/version
$	if $status
$	then
$	    cxx_avail = 1
$	endif
$!
$! Now let's see if we can use MMS/MMK, or if we have to build by hand.
$!
$	mms/help
$	if .not. $status
$	then
$	    if f$type (mmk) .nes. ""
$	    then
$	        use_mmk = 1
$		make_avail = 1
$	    endif
$	else
$	    make_avail = 1
$	endif
$	deassign sys$output
$	deassign sys$error
$
$	if test_no_cxx
$	then
$	    cxx_avail = 0
$	endif
$	if test_no_mms
$	then
$	    make_avail = 0
$	endif
$
$	save_dir = f$environment ("default")
$	test_dir = f$parse (save_dir,,,"directory")
$	if f$locate (".BUILD.VMS]", f$edit (test_dir, "upcase")) .eq. -
	   f$length (test_dir)
$	then
$	    say "You need to be in the ASTYLE [.build.vms] directory to run this."
$	    say "Aborting."
$	    status = 44
$	    goto exit
$	endif
$
$	create/dir [--.bin]/log
$	say "Setting default to the ASTYLE bin directory..."
$	set default [--.bin]
$
$	p1 = f$edit (p1, "upcase, collapse, uncomment")
$	if p1 .eqs. ""
$	then
$	    p1 = "MAIN"
$	endif
$	valid_p1 = ".MAIN.DEBUG.LIB.LIBDEBUG.JAVA.JAVADEBUG."
$	if f$locate (".''p1'.", valid_p1) .eq. f$length (valid_p1)
$	then
$	    say "Invalid parameter.  Please read the comments at the end of this"
$	    say "command procedure."
$	    status = 44
$	    goto exit
$	endif
$!
$	if f$search ("[-.src]*.cpp") .nes. ""
$	then
$	    say "The HP C++ compiler C++ likes files to be called .CXX"
$	    say "Renaming:"
$	    rename/log [-.src]*.cpp;* [-.src]*.cxx;*
$	endif
$
$	if .not. cxx_avail
$	then
$	    say "Artistic Style is written in C++.  You don't appear to have"
$	    say "the HP C++ compiler installed.  Attempting to link using objects..."
$	    if f$search ("sys$share:libcxxstd.olb") .eqs. "" .or. -
	       test_no_lib
$	    then
$		say "You don't appear to have to C++ runtime libraries installed."
$		say "Cannot continue."
$		status = 44
$		goto exit
$	    endif
$	endif
$
$	say "Building ASTYLE..."
$	set on
$	on warning then goto error
$	target = "astyle_main.exe"
$	if f$locate ("DEBUG", p1) .lt. f$length (p1)
$	then
$	    debug_flag = 1
$	    if .not. cxx_avail
$	    then
$		goto manual_link
$	    endif
$	endif
$	if f$locate ("LIB", p1) .lt. f$length (p1)
$	then
$	    lib_flag = 1
$	    target = "astyle_shr.exe"
$	    if .not. cxx_avail
$	    then
$		goto manual_link
$	    endif
$	endif
$	if f$locate ("JAVA", p1) .lt. f$length (p1)
$	then
$	    jni_flag = 1
$	    target = "astyle_jni.exe"
$	    jstart = f$edit (f$search ("sys$startup:java$%%%_setup.com"), "upcase")
$	    if jstart .eqs. ""
$	    then
$		say "You requested the Java Native Interface of ASTYLE, but the"
$		say "Java Development Kit is not installed - abort."
$		status = 44
$		goto exit
$	    else
$		@'jstart
$	    endif
$	    jver = f$parse (jstart,,,"name") - "_SETUP"
$	    jdir = f$trnlnm ("java$java_shr")
$	    x = f$locate (jver, jdir)
$	    prefix = f$extract (0, x + f$length (jver), jdir)
$	    ji1 = prefix + ".include]"
$	    ji2 = prefix + ".include.vms]"
$
$	    saveset = prefix + ".vms_demo]jni_example.sav"
$	    
$	    if f$search (saveset) .eqs. ""
$	    then
$		say "Can't locate required saveset " + prefix
$		say "Can't complete build of JNI version - abort."
$		status = 44
$		goto exit
$	    endif
$	    create/dir [-.build.vms.jni]
$	    backup/nolog 'saveset'/save [-.build.vms.jni]
$	    renamex/nolog [-.build.vms.jni]scan_globals_for_option.com []
$	    renamex/nolog [-.build.vms.jni]java$build_option.exe []
$	    if .not. cxx_avail
$	    then
$		goto manual_link
$	    endif
$	endif
$	if make_avail
$	then
$	    mflags = ""
$	    if debug_flag
$	    then
$		mflags = "debug=1,"
$	    endif
$	    if jni_flag
$	    then
$		mflags = mflags + "jni=1,ji1=''ji1',ji2=''ji2',"
$	    endif
$	    if lib_flag
$	    then
$		mflags = mflags + "lib=1,"
$	    endif
$	    if mflags .nes. ""
$	    then
$		mflags = f$extract (0, f$length (mflags) - 1, mflags)
$		mflags = "/macro=(" + mflags + ")"
$	    endif
$	    if use_mmk
$	    then
$		mmk [-.build.vms]descrip.mms'mflags 'target
$	    else
$		mms/extend/descrip=[-.build.vms]descrip.mms'mflags 'target
$	    endif
$	else
$	    if .not. cxx_avail
$	    then
$		goto manual_link
$	    endif
$	    cxx_flags = "/reent=multi/names=(shorten,as_is)"
$	    if debug_flag
$	    then
$	        cxx_flags = cxx_flags + "/debug/nooptimize"
$		if jni_flag
$		then
$		    cxx_flags = cxx_flags + -
				"/define=(astyle_jni=1,jit_option)" + -
				"/float=ieee/ieee=denorm"
$		endif
$		if lib_flag
$		then
$		    cxx_flags = cxx_flags + "/define=(astyle_lib=1)"
$		endif
$	    else
$	        cxx_flags = cxx_flags + "/nortti/nodebug/optimize"
$		if .not. jni_flag .and. .not. lib_flag
$		then
$		    cxx_flags = cxx_flags + "/define=(ndebug=1)"
$		endif
$		if jni_flag
$		then
$		    cxx_flags = cxx_flags + -
				"/float=ieee/ieee=denorm" + -
				"/define=(ndebug=1,astyle_jni=1,jit_option)"
$		endif
$		if lib_flag
$		then
$		    cxx_flags = cxx_flags + -
				"/define=(ndebug=1,astyle_lib=1)"
$		endif
$	    endif
$	    if f$search ("mms$olb.olb") .eqs. ""
$	    then
$		library/obj/cre mms$olb.olb
$	    endif
$	    cxx'cxx_flags' [-.src]asbeautifier
$	    library/obj/repl mms$olb.olb asbeautifier
$	    deletex/nolog asbeautifier.obj;*
$	    cxx'cxx_flags' [-.src]asenhancer
$	    library/obj/repl mms$olb.olb asenhancer
$	    deletex/nolog asenhancer.obj;*
$	    cxx'cxx_flags' [-.src]asformatter
$	    library/obj/repl mms$olb.olb asformatter
$	    deletex/nolog asformatter.obj;*
$	    cxx'cxx_flags' [-.src]asresource
$	    library/obj/repl mms$olb.olb asresource
$	    deletex/nolog asresource.obj;*
$	    if .not. jni_flag .and. .not. lib_flag
$	    then
$	        cxx'cxx_flags' [-.src]astyle_main
$	        cxxlink/exe=astyle_main.exe astyle_main,mms$olb/lib
$	    else
$		if jni_flag
$		then
$		    cxx'cxx_flags' [-.src]astyle_main/obj=astyle_jni.obj -
		    	/include=([],'ji1','ji2')
$		    @scan_globals_for_option astyle_jni.obj gs.opt
$	            cxxlink/share=astyle_jni.exe astyle_jni.obj, -
					         mms$olb.olb/lib, -
					         gs.opt/opt, -
					         [-.build.vms]java.opt/opt
$	        endif
$		if lib_flag
$		then
$		    cxx'cxx_flags' [-.src]astyle_main/obj=astyle_shr.obj
$		    cxxlink/share=astyle_shr.exe astyle_shr.obj, -
						 mms$olb.olb/lib, -
						 [-.build.vms]lib.opt/opt
$		endif
$	    endif
$	endif
$	goto exit
$manual_link:
$	dir/col=1/out=[-.build.vms]astyle.opt/nohead/notrail [.cxx_repository]*.obj;
$	if .not. jni_flag .and. .not. lib_flag
$	then
$	    link/exe=astyle_main.exe astyle_main.obj, -
				     mms$olb.olb/lib, -
				     [-.build.vms]astyle.opt/opt, -
				     sys$library:libcxxstd.olb/lib
$	else
$	    if jni_flag
$	    then
$	        @scan_globals_for_option astyle_jni.obj gs.opt
$	        link/share=astyle_jni.exe astyle_jni.obj, -
				          mms$olb.olb/lib, -
					  gs.opt/opt, -
					  [-.build.vms]astyle.opt/opt, -
				          [-.build.vms]java.opt/opt, -
				          sys$library:libcxxstd.olb/lib
$	    endif
$	    if lib_flag
$	    then
$	        link/share=astyle_shr.exe astyle_shr.obj, -
				          mms$olb.olb/lib, -
				          [-.build.vms]astyle.opt/opt, -
				          [-.build.vms]lib.opt/opt, -
				          sys$library:libcxxstd.olb/lib
$	    endif
$	endif
$	deletex/nolog [-.build.vms]astyle.opt;*
$	goto exit
$	    
$error:
$	status = $status
$exit:
$	set noon
$	say "Purging files..."
$	if f$search ("*.obj;-1") .nes. ""
$	then
$	    purgex/nolog *.obj
$	endif
$	if f$search ("[.cxx_repository]*.*;-1") .nes. ""
$	then
$	    purgex/nolog [.cxx_repository]*.*
$	endif
$	if f$search ("astyle_main.exe;-1") .nes. ""
$	then
$	    purgex/nolog astyle_main.exe
$	endif
$	if f$search ("gs.opt") .nes. ""
$	then
$	    deletex/nolog gs.opt;*
$	endif
$	if f$search ("java$build_option.exe") .nes. ""
$	then
$	    deletex/nolog java$build_option.exe;*
$	endif
$	if f$search ("scan_globals_for_option.com") .nes. ""
$	then
$	    deletex/nolog scan_globals_for_option.com;*
$	endif
$	say "Restoring environment..."
$	set default 'save_dir
$	if f$search ("jni.dir") .nes. ""
$	then
$	    deletex/nolog [.jni]*.*.*
$	    set prot=o:rwed jni.dir
$	    deletex/nolog jni.dir;
$	endif
$	if status
$	then
$	    say "Complete."
$	else
$	    say "Failed."
$	endif
$	exit (status + 0*f$verify (old_verify))
$!++
$!
$! DESCRIPTION
$!
$!	This file contains a simple build procedure for Artistic Style on
$!	OpenVMS systems.  You need the C++ compiler to compile ASTYLE from
$!	sources.  Problems with building or using ASTYLE on OpenVMS can be
$!	addressed to jim@eight-cubed.com.  Please ensure you read the
$!	OpenVMS specific installation instructions in the doc directory if
$!	you plan to use ASTYLE on ODS-2 disks, as there is a specific
$!	switch you must use to ensure original file renaming occurs
$!	properly.
$!
$!	The procedure takes one optional parameter.  If unspecified, the
$!	procedure builds the standalone executable image.  Specify "LIB" to
$!	build a sharable image that can be linked to and called from other
$!	executables.  Specify "JAVA" to build the Java Native Interface
$!	version that can be called from Java applications.  Additionally, you
$!	can append "DEBUG" to compile and link with debugger support.
$!
$!	For example:
$!
$!	    $ @vmsbuild		   ! Build the standalone exe
$!	    $ @vmsbuild debug	   ! Build the standalone exe with debug
$!	    $ @vmsbuild lib	   ! Build the sharable image
$!	    $ @vmsbuild java	   ! Build the JNI sharable image
$!	    $ @vmsbuild javadebug  ! Build the JNI sharable image with debug
$!
$! AUTHOR
$!
$!	James F. Duff
$!
$! DATE WRITTEN
$!
$!	08-Feb-2007
$!
$! MODIFICATION HISTORY
$!
$!	V01-00	08-Feb-2007	JFD	(Astyle version V1.20-2)
$!	Original version of module.
$!
$!	V01-01	07-Apr-2007	JFD	(Astyle version V1.21)
$!	Create bin directory; add /define=(ndebug=1)/nortti to compiles;
$!	redirect output of link to bin directory.
$!
$!	V01-02	17-Apr-2007	JFD	(Astyle version V1.21)
$!	Move objects/object libraries/c++ repository to the bin directory.
$!	Do manual link if the system does not have the C++ compiler.
$!
$!	V01-03  27-Jun-2007	JFD	(Astyle version V1.22)
$!	Correctly test the name of the build directory regardless of the
$!	process case lookup setting to deal with builds on ODS-5 disks.
$!
$!	V01-04	13-Mar-2008	JFD	(Astyle version V1.22)
$!	Change references to the "build" directory to the "buildvms" directory.
$!
$!	V01-05	29-Mar-2008	JFD	(Astyle version V1.22)
$!	Add support for building the LIB and JNI versions.
$!
$!	V01-06	11-Mar-2009	JFD	(Astyle version V1.24?)
$!	Fixed a descrepency between the documentation and the actual parameter
$!	to achieve a /DEBUG build of the main executable.  Additionally,
$!	added a flag to allow the simulation of no c++ compiler, no mms,
$!	and no SYS$SHARE:LIBCXXSTD.OLB.  Support new directory structure.
$!--
