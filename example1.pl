#!/usr/bin/perl
use v5.14;                              # use and enable features since 5.14
use feature qw{ say  };                 # or enable say from new features

print "\$someinput: ";                  # 'print' without newline
chop(my $someinput=<STDIN>);            # initialise skalar '$someinput' from '<STDIN>'
say "output \$someinput: <$someinput>"; # 'say' is only available if you define 'use v5.10.0' or higher
say 'print the string $someinput: without interpolation';
