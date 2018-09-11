# perl5-hints

# header and language usage

```perl
#!/usr/bin/perl
use v5.14;              # enables say, enables use strict;
say "Hello world!";
% Hello world!
```

# variables

| Type       | Sigil | Example  | Meaning                                   |
|------------|-------|----------|-------------------------------------------|
| Scalar     | $     | $hello   | An individual value (number or string)    |
| Array      | @     | @array   | A list of values, keyed by number [0,1..] |
| Hash       | %     | %hash    | A group of values, keyed by number        |
| Subroutine | &     | &how     | A callable chunk of Perl code how()       |
| Typeglob   | *     | \*struck | Everything named *struck*                 |

# Scalar

```perl
my $hello = "Hello world!\n";   # with interpolation of \n
print $hello;
% Hello world
```

```perl
my $hello = 'Hello universe\n';    # no interpolation
print $hello;
% Hello universe\n
```

# Array

## Define an Array

```perl
my @array;
$array[0] = "Chuck";
$array[1] = "Tim";
$array[2] = "Arnold";
```

## Loop over an Array

```perl
for my $user (@array) {
    say "For-Loop User: $user";
}

% For-Loop User: Chuck
% For-Loop User: Tim
% For-Loop User: Arnold
```
## Define an Array in one-line

```perl
@array = ("Sonja", "Rose", "Vicky", "Florence");
```

## Copy position 1 to End of Array to new array
```perl
@names = @array[ 1 .. $#array ];
```

## Loop over an Array and return index and value
```perl
my @names = @array[ 1 .. $#array ];
foreach my $i (0 .. $#names) {
    say "$i - $names[$i]";
}

% 0 - Rose
% 1 - Vicky
% 2 - Florence
```

## Print Array with Data::Dumper

Backslash @Array means here an reference to the array.

```perl
use Data::Dumper;
print Dumper \@names;
$VAR1 = [
          'Rose',
          'Vicky',
          'Florence'
        ];
```
