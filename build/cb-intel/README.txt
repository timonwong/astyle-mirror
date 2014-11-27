
Projects using -static-intel have the linker option  -wd10237
This removes the warning:
warning #10237: -lcilkrts linked in dynamically, static library not available

-----------------------------------------------------------
RELEASE 2015-1.133
-----------------------------------------------------------
The Release compile displays the remarks:
remark #11074: Inlining inhibited by limit max-size
remark #11074: Inlining inhibited by limit max-total-size
remark #11076: To get full report use -qopt-report=4 -qopt-report-phase ipo

To remove the remarks:
add the option -Wextra
or -wd11074,11076
Do NOT use -no-inline-max-total-size

-----------------------------------------------------------
RELEASE 2013-sp1.1.106 - fixed in release 2015-1.133
-----------------------------------------------------------
The Intel compiler release 2013-sp1.1.106, testing for
AStyle 2.05, contains a bug which will cause compile errors.
http://software.intel.com/en-us/forums/topic/475786

The shell script intel-fix.sh will execute CodeBlocks with
an environment variable set to the value which will correct
the problem.

The script will not be necessary when the bug is fixed.

-----------------------------------------------------------
FIX HISTORY
-----------------------------------------------------------
RELEASE 2013-sp1.1.106, testing for AStyle 2.05.
    A temporary compiler bug work-around, from
    http://software.intel.com/en-us/forums/topic/475786.
    The compile options must include
    -I/usr/include/x86_64-linux-gnu/c++/4.8.
    This can be done by setting the __INTEL_POST_CFLAGS
    environment variable.
REMOVED in release 2011.1.107.
    -vec-report0 turns off BLOCK WAS VECTORIZED warnings.
    To disable vectorization use -mia32 instead.
    -no-multibyte-chars is a temporary work-around, from
    http://software.intel.com/en-us/forums/intel-c-compiler/topic/56258.
If the intel compiler version doesn't support the current GCC headers
    use -gxx-name=g++-4.x where x is a previous GCC compiler.
