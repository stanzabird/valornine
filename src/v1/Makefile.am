BUILT_SOURCES = parser.h

AM_YFLAGS = -d -t
AM_LFLAGS = -d

# enable profiling:
#AM_CXXFLAGS =-pg
#AM_CFLAGS =-pg

bin_PROGRAMS = vn
vn_SOURCES = generator.h generator.cc generator-liquid.cc generator-print.cc generator-lsmod.cc main.cc parser.types.h parser.y scanner.l symtab.h symtab.cc trim.h trim.cc
