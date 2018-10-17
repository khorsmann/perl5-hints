#!/usr/bin/perl
use v5.14;                              # use and enable features since 5.14
use Data::Dumper;

say "Setup an empty array";
say 'my @array;';

my @array;

say "Fill in Values into the existing array";
my $msg = <<'EOF';
    $array[0] = "Chuck";
    $array[1] = "Tim";
    $array[2] = "Arnold";
EOF

say $msg;

$array[0] = "Chuck";
$array[1] = "Tim";
$array[2] = "Arnold";

say "##############################################";
say "Iterate over an array";
my $msg = <<'EOF';

    for my $user (@array) {
        say "For-Loop User: $user";
    }
EOF
say $msg;

for my $user (@array) {
    say "For-Loop User: $user";
}

say "##############################################";
say "or you can setup an array in one-line";
say '@array = ("Sonja", "Rose", "Vicky", "Florence");';
@array = ("Sonja", "Rose", "Vicky", "Florence");
say "";

say "##############################################";
say 'copy from position 1 to end of array to new array @names';
say '@names = @array[ 1 .. $#array ];';
say "";

my @names = @array[ 1 .. $#array ];
foreach my $i (0 .. $#names) {
    say "$i - $names[$i]";
}

say "##############################################";
say "array-end-pos: $#array";
say "last array element: $array[-1]";
print Dumper \@names;

say "##############################################";
say "replace an explicit position in array";
my $msg = <<'EOF';

    $array[2] = "second entry";
    $array[0] = "first entry";
EOF
say $msg;
print Dumper \@array;

say "##############################################";
say "insert something into the middle or somewhere";
splice @array, 2, 0, "Splice something at Index number 2";
print Dumper \@array;

