# perl5-hints

# header and language usage

```perl
#!/usr/bin/perl
use v5.14;              # enables say, enables use strict;
say "Hello world!";
% Hello world!
```

# variables

| Type       | Sign | Example  | Meaning                                   |
|------------|------|----------|-------------------------------------------|
| Scalar     | $    | $hello   | An individual value (number or string)    |
| Array      | @    | @array   | A l8st of values, keyed by number [0,1..] |
| Hash       | %    | %hash    | A group of values, keyed by number        |
| Subroutine | &    | &how     | A callable chunk of Perl code how()       |
| Typeglob   | *    | \*struck | Everything named *struck*                 |

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

```perl
my @array;
$array[0] = "Chuck";
$array[1] = "Tim";
$array[2] = "Arnold";

for my $user (@array) {
    say "For-Loop User: $user";
}

% For-Loop User: Chuck
% For-Loop User: Tim
% For-Loop User: Arnold
```


