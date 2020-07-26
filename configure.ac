AC_INIT([valornine], [2.0.0], [bert@stanzabird.nl], [], [https://github.com/stanzabird/valornine/])
AC_CONFIG_SRCDIR(src/main.cc)
AC_CONFIG_MACRO_DIR([m4])
AC_PREREQ(2.59)
AM_INIT_AUTOMAKE
AC_CONFIG_HEADERS(config.h)

AC_PROG_CC
AC_PROG_CXX

AC_LANG([C++])
AX_CXX_COMPILE_STDCXX_17

AX_PROG_FLEX
AX_PROG_BISON

AC_CONFIG_FILES(Makefile src/Makefile src/v1/Makefile proposals/Makefile)
AC_OUTPUT
