#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.001';

use Cwd 'abs_path';
use Carp qw(croak carp);
use File::Basename;
use File::Spec::Functions qw(abs2rel);
#use Test::More tests => 5;

# CPAN Addons:
use Test2::V0 '!meta';
use Test::Script;
use Test::Perl::Critic 1.02;

my $SCRIPT_NAME = q{checkinstall.pl};
my $WORK_DIR    = dirname(abs_path(__FILE__));
my $SOURCE_DIR  = abs_path($WORK_DIR . q{/..});
my $ABS_SCRIPT  = abs_path($SOURCE_DIR . q{/} . $SCRIPT_NAME);
my $SCRIPT      = abs2rel($ABS_SCRIPT, $WORK_DIR);

note "w-dir: $WORK_DIR";
note "s-dir: $SOURCE_DIR";
note "abs-script: $ABS_SCRIPT";
note "script: $SCRIPT";
note "script-name: $SCRIPT_NAME";

# some tests are relative to WORK_DIR, so go into that directory.
chdir $WORK_DIR or croak ("could not change DIR to $WORK_DIR");

# Test::Perl::Critic
critic_ok($SCRIPT);

# Test::Script
script_compiles($SCRIPT, 'Main script compiles');

script_runs($SCRIPT, 'Main script runs');
script_stdout_like q{'checkinstall.pl --help'}, 'Run without params. Show help advice.';

# Prepare
my @run_it = ($SCRIPT, '--dir');
my %options = (exit => 255);
my $response = "Option dir requires an argument\n" . 'Error in command line Arguments. Use -h for help.';

script_runs(\@run_it, \%options, "$SCRIPT_NAME --dir. Not enough arguments. Exits with $options{exit}");
script_stderr_like $response, "$SCRIPT_NAME --dir. Not enough params.";


# Prepare
@run_it = ($SCRIPT, '--check', '--force');
%options = (exit => 2);
script_runs(\@run_it, \%options, "$SCRIPT_NAME --check --force . Wrong --dir. Exits with $options{exit}");

done_testing;

