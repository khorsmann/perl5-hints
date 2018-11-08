#!/usr/bin/perl

use strict;
use warnings;
use English;
use Carp qw(croak carp);

print "try/fetch exceptions\n";
print "--------------------------------------\n";

eval {
    # code that might throw exception
    die('Dead');
};
if ($@) {
    # you can not rely
    # report the exception and do something about it
    print "exception: $@";
}
# prints:
# Dead at exceptions.pl line 13.

print "everything else works.\n";
print "--------------------------------------\n";
print "same with croak:\n";

eval {
    croak('Dead with croak');
};

if ($@) {
    carp("Another exception: $@");
}

print "--------------------------------------\n";
print "same with long-wording of use English\n";

eval {
    croak("Die again!");
};
if ($EVAL_ERROR) {
    carp("And anotherone: $EVAL_ERROR");
}

print "--------------------------------------\n";
print "False/Positiv with eval!\n";
print "eval() returns True on catched exception\n";
sub return_false {
    return 0;
}

if ( eval { return_false() } ) {
    carp("exception $@");
}

print "--------------------------------------\n";
print "Avoid False/Positiv with eval!\n";

if ( eval { return_false(); 1 } ) {
    carp("exception $@");
}

print "EOF\n";
