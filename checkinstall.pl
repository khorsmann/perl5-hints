#!/usr/bin/perl

use strict;
use warnings;
use 5.008_000;

our $VERSION = '0.001';

use Cwd 'abs_path';
use Carp qw(croak carp);
use Data::Dumper qw(Dumper);
use Digest::file qw(digest_file_hex);
use English qw( -no_match_vars )
    ;    # Avoids regex performance penalty in perl 5.16 and earlier
use Fcntl ':mode';
use File::Basename;
use File::Find;
use File::stat;
use File::stat ':FIELDS';
use File::Spec::Functions qw(abs2rel);
use Getopt::Long;
use Term::ANSIColor;

my $SOURCEDIR  = dirname( abs_path(__FILE__) );
my $SCRIPTNAME = basename(__FILE__);
my $CSV_FILE   = join q{/}, ( $SOURCEDIR, 'checkinstall.csv' );
my $COLOR      = 0;
my @CSV_ENTRIES;
my @FOUND;
my @FTYPES;

$FTYPES[S_IFDIR]  = q{d};
$FTYPES[S_IFCHR]  = q{c};
$FTYPES[S_IFBLK]  = q{b};
$FTYPES[S_IFIFO]  = q{f};
$FTYPES[S_IFLNK]  = q{l};
$FTYPES[S_IFSOCK] = q{s};
$FTYPES[S_IFREG]  = q{-};

my @KEYNAMES = qw(name uid_name gid_name uid gid octperm mode ftype digest);

sub color_print {
    my ( $input, $color_args, $color ) = @_;
    if ( $color && $color_args ) {
        return print colored( [$color_args], $input );
    }
    return print $input;
}

sub y_print {
    my ($input) = @_;
    return color_print( $input, 'yellow on_black', $COLOR );
}

sub r_print {
    my ($input) = @_;
    return color_print( $input, 'red on_black', $COLOR );
}

sub g_print {
    my ($input) = @_;
    return color_print( $input, 'green on_black', $COLOR );
}

sub b_print {
    my ($input) = @_;
    return color_print( $input, 'blue on_black', $COLOR );
}

sub sha256sum {
    my ($input) = @_;
    return digest_file_hex( ($input), 'SHA-256' );
}

sub is_dir_empty {
    my ($dir) = @_;

    # returns false / 0 if directory is not empty
    return 0 if not -e $dir;    # does not exist
    return 0 if not -d $dir;    # in not a directory

    opendir my $d, $dir or      # likely a permissions issue
        croak "Can't opendir <$dir>, because: <$OS_ERROR>\n";

    my $count = scalar glob $dir;
    if ($count) {
        return 0;
    }

    return 1;
}

sub preprocess {
    my (@input) = @_;

    # helper function for find_dir_file()
    # input-type is @array.
    # ignore unwanted files
    # returns @array
    my $a_out = basename($CSV_FILE);
    my $b_out = basename( $SCRIPTNAME, q{.pl} ) . q{.csv};
    return grep {
               !/.vscode/smx
            && !/.git/smx
            && !/.gitignore/smx
            && !/setup.py/smx
            && !/README.md/smx
            && !/CHANGELOG.md/smx
            && !/$SCRIPTNAME/smx
            && !/$a_out/smx
            && !/$b_out/smx
    } @input;
}

sub wanted {
    my ($fname) = $_;
    # helper function for find_dir_file()
    if ( -f $fname or -d $fname ) {
        push @FOUND, $File::Find::name;
    }
    return 1;
}

sub find_dir_file {
    find(
        {   preprocess => \&preprocess,
            wanted     => \&wanted,
            no_chdir   => 0
        },
        $SOURCEDIR
    );

    # remove empty folders
    for my $idx (@FOUND) {
        if ( -d $idx && is_dir_empty($idx) ) {
            pop @FOUND;    # remove entry from @Found
            next;          # skip the remove one
        }
        push @CSV_ENTRIES, get_permission($idx);
    }
    return 1;              # True
}

sub get_permission {
    my ($fh) = @_;
    # todo - if symbolic link, dont save the stuff about rights.
    # use lstat to get status info for symbolic link instead of target file
    lstat $fh
        or croak "Can't stat <$fh> : <$OS_ERROR>" ;


    my $relname = abs2rel( $fh, $SOURCEDIR );
    my $octperm  = sprintf '0%o', S_IMODE($st_mode);
    my $uid_name = getpwuid $st_uid;
    my $gid_name = getgrgid $st_gid;
    my $filetype = $FTYPES[ S_IFMT($st_mode) ];
    my $digest   = q{};                                # empty string
    if ( S_ISREG($st_mode) ) {
        $digest = sha256sum($fh);
    }

    # Folder or File relative to source is a dot sign.
    if ( $relname eq q{.} ) { return; }

    my %permissions = (
        'name'     => $relname,
        'uid_name' => $uid_name,
        'gid_name' => $gid_name,
        'uid'      => $st_uid,
        'gid'      => $st_gid,
        'octperm'  => $octperm,
        'mode'     => $st_mode,
        'ftype'    => $filetype,
        'digest'   => $digest,
    );
    return \%permissions;
}

sub compare_hash_values {

    # compare HashValues as strings
    # first inputHash is actual value, second inputHash is target value
    # third argument (optional), verbose printing of diff
    #
    # the smart operator ~~ is much short but deprecated for this.
    my ( $a, $b, $verbose ) = @_;
    if ( !%{$a} || !%{$b} ) { return 0; }   # if one ref-hash is empty - exit!
    my $diff = 0;
    foreach my $key ( sort keys %{$a} ) {
        if ( exists $b->{$key} ) {
            if ( "$a->{$key}" ne "$b->{$key}" ) {
                if ($verbose) {
                    if ( !$diff ) {
                        y_print("\n");
                    }
                    r_print("\t$key: [$a->{$key}] and should be\n");
                    g_print("\t$key: [$b->{$key}]\n");
                }
                $diff++;
            }
        }
        else {
            # a-key dont exists b
            $diff++;
        }
    }

    if ( $diff == 0 ) { return 1; }    # True
    return 0;                          # False

}

sub set_permission {
    my ($a) = @_;
    if (   ( exists $a->{name} )
        && ( exists $a->{octperm} )
        && ( exists $a->{uid_name} )
        && ( exists $a->{gid_name} ) )
    {

        my $uid = getpwnam $a->{uid_name};
        my $gid = getgrnam $a->{gid_name};
        my $fh  = join q{/}, ( abs_path($SOURCEDIR), $a->{name} );

        y_print("\tchmod $a->{octperm} $fh\n");
        chown $uid, $gid, $fh or croak "Can't chown $fh $OS_ERROR";

        y_print("\tchown $a->{uid_name}:$a->{gid_name} $fh\n");
        chmod oct( $a->{octperm} ), $fh or croak "Can't chmod $fh $OS_ERROR";
    }
    else {
        return 0;    # False
    }
    return 1;        # True
}

sub write_csv {
    my $delimiter = q{;};
    open my $filehandle, '>:encoding(UTF-8)', $CSV_FILE
        or croak("Could not open file '$CSV_FILE' $OS_ERROR");

    for my $line (@CSV_ENTRIES) {
        print {$filehandle} join( $delimiter, @{$line}{@KEYNAMES} ) . "\n"
            or croak("Could not write to file '$CSV_FILE' $OS_ERROR");
    }
    close $filehandle
        or croak("Could not close file '$CSV_FILE' $OS_ERROR");
    return 1;    # True
}

sub read_csv {

    # alternative is Perl6::Slurp slurp method
    open my $filehandle, '<:encoding(UTF-8)', $CSV_FILE
        or croak("Could not open file '$CSV_FILE' $OS_ERROR");
    chomp( my @csvarray = <$filehandle> );
    if ( !close $filehandle ) {
        croak("Could not close file '$CSV_FILE' $OS_ERROR");
    }

    my $empty = q{};
    for my $line (@csvarray) {
        my @values = split m/[;]/sxm,
            $line;    # split always interprets the PATTERN argument as regex!

        # check if @values array is not empty
        if (@values) {

        # check if $values[$_] is not empty.
        # If its empty, it will be "undef"
        # and that will break other things.
        # so set $empty (empty string)
        # as default value if $values[$_] is "undef".
            push @CSV_ENTRIES, {
                map {
                          $KEYNAMES[$_] => defined $values[$_]
                        ? $values[$_]
                        : $empty
                } ( 0 .. $#KEYNAMES )
            };
        }
    }
    return 1;    # True
}

sub show_help {
    my $help_msg = <<"EOF";
Usage $SCRIPTNAME [OPTIONS]

Optional Arguments:
    --help, -h, -?       for help
    --debug, -d          for debug and exit without doing
    --filename=Filename  CSV_FILE for READING/WRITING (default=$CSV_FILE)
    --dir=Folder         ROOT_DIRECTORY for GET/SET Permissions (default=$SOURCEDIR)
    --update             Updates CSV_FILE with FILES/DIRS that are in $CSV_FILE and $SOURCEDIR
                         needs --setperm or --getperm
    --color              turn on colored output
Needed Arguments:
    --check              CHECK FILE and DIRECTORY Permissions of <dir> from <filename>
    --setperm            SET FILE and DIRECTORY Permissions of <dir> from <filename>
    --getperm            GET FILE and DIRECTORY Permissions of <dir> to <filename>

EOF
    return print $help_msg;
}

sub yesno {

    # Todo Check for interactive shell
    # Todo Support for Quit via CTRL+C
    my ( $question, $force ) = @_;

    y_print("$question");
    if ( defined $force && $force ) {
        y_print "Force active\n";
        return 1;
    }

    y_print("\nEnter *Y*es|*N*o: ");

    chomp( my $input = <> );
    if ( $input =~ /^[Y|J]?$/xsmi ) {
        return 1;    # True
    }
    elsif ( $input =~ /^[Q|N]$/xsmi ) {
        return 0;    # False
    }
}

# main helper
sub get_perm {

    # get permissions
    my (%h) = @_;
    my $force = $h{force};
    my $question =
        "Get Permissions of <${$h{dir}}> and write it to <${$h{filename}}>?\n";
    if ( !yesno( $question, $force ) ) { return 0; }

    if ( find_dir_file() ) {
        if ( $h{debug} ) { y_print( Dumper \@CSV_ENTRIES ) }
        if ( write_csv() ) {
            g_print("...done\n");
        }
    }
    return 1;    # True
}

sub _validate_or_set_perm {
    my (%h) = @_;

    # Todo - check for $h{setperm} is defined!

    foreach my $target (@CSV_ENTRIES) {
        my $fh = join q{/}, ( abs_path($SOURCEDIR), $target->{name} );
        y_print("Processing <$fh> ");
        my $status = get_permission($fh);
        if ( !%{$status} ) {
            r_print("\nCould not open $fh...skip\n");
            next;
        }
        if ( !compare_hash_values( $status, $target, $h{check} ) ) {
            if ( $h{setperm} ) {
                r_print("not the same permissions! Try to fix it\n");
                if ( set_permission($target) ) {
                    g_print("...done\n");
                }
                else {
                    r_print("...failed!\n");
                    return 0;    # False
                }
            }
        }
        else {
            g_print("...okay.\n");
        }
    }
    return 1;                    # True
}

sub _prepare {
    my (%h) = @_;
    y_print('Try to read permissions from file to RAM');
    if ( read_csv() ) {
        g_print("...done\n");
    }
    if ( !@CSV_ENTRIES ) {
        r_print("\n");
        r_print("No entries in <${$h{filename}}>! - ABORT!\n");
        return 0;                # False
    }
    return 1;
}

sub check {
    my (%h) = @_;
    my $force = $h{force};
    my $question =
        "Check Files from CSV <${$h{filename}}> and GET PERMISSIONS of <${$h{dir}}>?\n";

    if ( !yesno( $question, $force ) ) { return 0; }
    if ( !_prepare(%h) ) { return 0; }
    if ( !_validate_or_set_perm(%h) ) { return 0; }
    return 1;    # True
}

sub set_perm {

    # set permissions
    my (%h)      = @_;
    my $force    = $h{force};
    my $qa       = "SET Permissions of <${$h{filename}}> and write ";
    my $question = $qa . "it to <${$h{dir}}> files and folders?\n";

    if ( !yesno( $question, $force ) ) { return 0; }
    if ( !_prepare(%h) ) { return 0; }
    if ( !_validate_or_set_perm(%h) ) { return 0; }
    return 1;    # True
}

sub get_perm_update {

    # get permissions and update
    my (%h) = @_;
    my $force = $h{force};
    my $qa = "Get Files from CSV <${$h{filename}}> and GET PERMISSIONS of ";
    my $question = $qa . "<${$h{dir}}> and write it to <${$h{filename}}>?\n";

    if ( !yesno( $question, $force ) ) { return 0; }
    if ( !_prepare(%h) ) { return 0; }

    my $index   = 0;
    my $changes = 0;
    foreach my $target (@CSV_ENTRIES) {
        my $fh = join q{/}, ( $SOURCEDIR, $target->{name} );
        y_print("Processing <$fh> ");
        my $status = get_permission($fh);
        if ( !compare_hash_values( $status, $target ) ) {
            if ( ( $h{getperm} ) && ( $h{update} ) ) {
                r_print("not the same permissions! Update CSV Entry\n");
                $CSV_ENTRIES[$index] = $status;
                $changes++;
            }
        }
        else {
            g_print("...done\n");
        }
        $index++;
    }
    if ($changes) {
        y_print("They are $changes changes so we wrote the $CSV_FILE again ");
        if ( write_csv() ) {
            g_print("...done\n");
        }
    }
    return 1;    # True

}

sub set_perm_update {
    my (%h) = @_;
    my $force = $h{force};

    # set permissions and update
    my $qa       = "Update Filelist from CSV <${$h{filename}}> with files\n";
    my $question = $qa
        . "that are there in <${$h{dir}}> and write it to <${$h{filename}}>?\n";

    if ( !yesno( $question, $force ) ) { return 0; }
    if ( !_prepare(%h) ) { return 0; }

    my $index = 0;
    foreach my $target (@CSV_ENTRIES) {
        y_print("Processing <$target->{name}> \n");
        my $fh = join q{/}, ( $SOURCEDIR, $target->{name} );

        # check if target is here or not
        if ( !-f $fh ) {
            if ( !-d $fh ) {
                r_print("<$fh> not here! - Delete it from Index \n");
                delete $CSV_ENTRIES[$index];
                next;
            }
        }
        $index++;
    }

    if ( !write_csv() ) { return 0; }
    return 1;    # True

}

sub _get_working_dir {

    my ($dir) = @_;
    # return reference, validated, formated Directory - or default Directory
    if ($dir) { return \abs_path( File::Spec->canonpath($dir) ); }
    return \$SOURCEDIR;
}

sub do_main {

    my %h = (
        'help'     => 0,
        'debug'    => 0,
        'setperm'  => q{},
        'getperm'  => q{},        # option variable with default value (false)
        'filename' => \$CSV_FILE, # Ref to $CSV_FILE, so its global writable
        'dir'    => \$SOURCEDIR,  # Same here
        'update' => undef,
        'check'  => 0,
        'color'  => \$COLOR,
        'force'  => 0,
    );

    GetOptions(
        \%h,         'help|?',  'debug|dd',     'setperm|s',
        'getperm|g', 'dir|d=s', 'filename|f=s', 'update|u',
        'check|c',   'color',   'force'
    ) or die "Error in command line Arguments. Use -h for help.\n";

    if ( $h{debug} ) { y_print( Dumper( \%h ) ) }

    $h{dir} = _get_working_dir( ${ $h{dir} } );

    if ( !-d ${ $h{dir} } ) {
        die "Dir <${$h{dir}}> is not a directory! $!\n";
    }

    if ( ( $h{setperm} ) && ( $h{update} ) ) {
        return set_perm_update(%h);
    }

    if ( $h{getperm} && $h{update} ) {
        return get_perm_update(%h);
    }

    if ( $h{setperm} ) {
        return set_perm(%h);
    }

    if ( $h{getperm} ) {
        return get_perm(%h);
    }

    if ( $h{check} ) {
        return check(%h);
    }

    if ( $h{help} ) {
        show_help();
        return 0;
    }
    y_print("Try '$SCRIPTNAME --help' for more information.\n");
    return 0;

}

# Call main
do_main();
1;
