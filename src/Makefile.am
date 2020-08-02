AM_YFLAGS = -d -t --warning=none
SUBDIRS = v1 syntax
bin_PROGRAMS = vn
vn_CCFLAGS = --warning=none
vn_SOURCES = main.cc vn2syntax.formal.y
vn_LDADD = -L syntax -lsyntax
EXTRA_DIST=vn2syntax.vn
