#!/usr/bin/perl
use v5.14;                              # use and enable features since 5.14

my @array;
$array[0] = "Chuck";
$array[1] = "Tim";
$array[2] = "Arnold";

for my $user (@array) {
    say "For-Loop User: $user";
}
