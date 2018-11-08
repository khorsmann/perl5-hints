#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(croak carp);
print "try/fetch exceptions\n";
eval {
    # code that might throw exception
    die('Dead');
};

if ($@) {
    # report the exception and do something about it
    print "exception: $@";
}
# prints:
# Dead at exceptions.pl line 10.

print "everything else works.\n";
print "\n";
print "same with croak:\n";

eval {
    croak('Dead with croak');
};

if ($@) {
    carp("Another exception:");
}

