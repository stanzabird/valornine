AC_INIT([valornine], [0.3.1], [bert@stanzabird.nl], [], [https://github.com/stanzabird/valornine/])
AC_CONFIG_SRCDIR(src/main.cc)
AC_CONFIG_MACRO_DIR([m4])
AC_PREREQ(2.59)
AM_INIT_AUTOMAKE
AC_CONFIG_HEADERS(config.h)

AC_PROG_CC
AC_PROG_CXX

AC_LANG([C++])
AX_CXX_COMPILE_STDCXX_14

AX_PROG_FLEX
AX_PROG_BISON

AC_CONFIG_FILES(Makefile src/Makefile proposals/Makefile)
AC_OUTPUT
