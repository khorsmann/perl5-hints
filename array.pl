#!/usr/bin/perl
use v5.14;                              # use and enable features since 5.14
use Data::Dumper;

my @array;
$array[0] = "Chuck";
$array[1] = "Tim";
$array[2] = "Arnold";

for my $user (@array) {
    say "For-Loop User: $user";
}
say "";

say "or you can setup an array in one-line";
say '@array = ("Sonja", "Rose", "Vicky", "Florence");';
@array = ("Sonja", "Rose", "Vicky", "Florence");
say "";

say "copy position 1 to End of Array to new array";
say '@names = @array[ 1 .. $#array ];';
say "";

my @names = @array[ 1 .. $#array ];
foreach my $i (0 .. $#names) {
    say "$i - $names[$i]";
}

say "array-end-pos: $#array";
say "last array element: $array[-1]";
print Dumper \@names;
