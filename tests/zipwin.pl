#!/usr/bin/env perl

use strict;
no warnings;

# constants, if the script doesn't work, check these first
my $objdump32="i686-w64-mingw32-objdump";
my $objdump64="x86_64-w64-mingw32-objdump";
my $dlldir32="/usr/i686-w64-mingw32/sys-root/mingw/bin/";
my $dlldir64="/usr/x86_64-w64-mingw32/sys-root/mingw/bin/";

#
# parse commandline
#

my $argc = $#ARGV + 1;

if ($argc <= 1) {
    print "Use: zipwin.pl [32|64] executable_name\n";
    exit;
}

my $is32_64 = $ARGV[0];
if ($is32_64 != "32" and $is32_64 != "64") {
    print "First argument must be '32' or '64'.\n";
    exit
}

my $exename = $ARGV[1];
if ( not (-e $exename) ) {
    print "Program file '$exename' does not exist.\n";
    exit;
}

my @exe_split = split('\.', $exename);
my $progname=$exe_split[0];	# basename of the program executable

#constants
my $zipsuffix32="win32";
my $zipsuffix64="win64";

#
# set arch dependent variables
#

my $objdump=$objdump32;
my $dlldir=$dlldir32;
my $zipsuffix=$zipsuffix32;

if ($is32_64 == "64") {
    $objdump=$objdump64;
    $dlldir=$dlldir64;
    $zipsuffix=$zipsuffix64;
}

#
# functions
#

# argument: a list of dll-deps that may contain non-existing deps (windows builtin)
# return: a list of dll-deps that are actually found
sub clean_deps {
    my @found_deps = ();

    foreach(@_) {
	my $filename = "$dlldir$_";
	if (-e $filename) { push(@found_deps, $_); }
    }

    return @found_deps;
}

# argument: module (.exe or .dll) of which to find the dependencies
# returns: list of dependent dll modules (cleaned of non-existing ones)
sub get_deps {
    my $modulename = $_[0];
    my $cmd = "$objdump -x $modulename  | grep -i \"dll name\" | awk '{print \$3}'";
    my $output= `$cmd`;

    return sort(clean_deps(split('\n', $output)));
}

# argument: list of dll's of which to find the dependencies
# returns: list of deps for each dll (cleaned but with duplicates)
sub recurse_deps {
    my @newdeps = ();

    foreach (@_) {
	my $filename = "$dlldir$_";
	push(@newdeps, get_deps($filename));
    }

    return sort(clean_deps(@newdeps));
}

# argument: list to remove duplicates from
# return: list without duplicates
sub uniq {
    # use a hash
    my %hash = map {$_, 1} @_;
    my @unique = keys %hash;
    return sort(@unique);
}


#
# do the thing
#


my $exe = "$progname.exe";
my @deps = get_deps($exe);

#print "exe=$exe; deps=@deps";
#print "---";

# my @deps = ();
# my $exe_name = $ARGV[2];
# my $exe = "$exe_base.exe";

#foreach $exe_base (@ARGV[1..$ARGC]) {
#    print "$exe";
#    print "@deps";
#    push(@deps, get_deps($exe));
#    print "@deps"
#}



# PRE: @deps $exe

my @t = sort(uniq(@deps));

do {
    @deps = @t;
    push (@t, recurse_deps(@deps));
    @t = sort(uniq(@t));
} while (not(@t ~~ @deps));

@deps = @t;

print "executable:   $exe\n";
print "dependencies: @deps\n";

my @fullnames = (); foreach (@deps) { push(@fullnames, "$dlldir$_"); }
my $cmd = "zip -j9 $progname-$zipsuffix.zip $progname.exe @fullnames";

print "\n$cmd\n\n";
system $cmd;


