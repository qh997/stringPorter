#!/usr/bin/perl

use warnings;
use strict;
use Cwd;
use Getopt::Long;
use Pod::Usage;
use File::Find;
use Text::CSV;

my $BASEPATH = getcwd;
my $OUTFILE = 'strings.csv';
my $HELP = 0;
my $DEBUG = 0;
my @LANGUAGE = (
    'values',
);
my %TYPES = (
    'string' => 'SINGLE',
    'string-array' => 'MULTI',
    'plurals' => 'SINGLE',
);

GetOptions (
    'path=s' => \$BASEPATH,
    'out=s'  => \$OUTFILE,
    'help|?' => \$HELP,
    'debug'  => \$DEBUG,
) or pod2usage(2);

if ($HELP) {
    pod2usage(1);
    exit 0;
}

-d $BASEPATH or die "$BASEPATH: $!\n";
$BASEPATH =~ s{(?<!/)$}{/};

print "$BASEPATH\n" if $DEBUG;
print "$OUTFILE\n" if $DEBUG;

my $prelang = join '|', @LANGUAGE;
$prelang =~ s/(?=[.()])/\\/g;

my @file_list;
find(\&wanted, $BASEPATH);

my $findType = join '|', keys %TYPES;

open my $oh, "> ".$OUTFILE or die "$OUTFILE: $!";
my $csv = Text::CSV->new({binary => 1, eol => $/})
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
#$csv -> eol("\r\n");
$csv->print($oh, ['File path', 'Type', 'name', 'value']);

my @out;
foreach my $file (@file_list) {
    open my $fh, "< $file" or warn "$file: $!" and next;
    my @file_content = <$fh>;
    close $fh;

    my $file_path = $file;
    $file_path =~ s/^$BASEPATH//;
    print $file."\n" if $DEBUG;

    my $filestring = join '', @file_content;
    $filestring =~ s/<!--.*?-->//sg;

    while ($filestring =~ m{<($findType).*?name="(.*?)".*?>(.*?)</\1.*?>}xsg) {
        my $stype = $1;
        my $sname = $2;
        my $svalue = $3;

        if ($stype eq 'string-array') {
            while ($svalue =~ m{<item>(.*?)</item>}sg) {
                my $svalue_item = $1;
                $csv->print($oh, [$file_path, $stype, $sname, $svalue_item]);
            }
        }
        else {
            $csv->print($oh, [$file_path, $stype, $sname, $svalue]);
        }
    }
}

close $oh or die "$OUTFILE: $!";

sub wanted {
    if (-f $File::Find::name) {
        if ($File::Find::name =~ m{/$prelang/strings\.xml$}) {
            my $basepath = $BASEPATH;
            $basepath =~ s/(?=[.()])/\\/g;

            my $filename = $File::Find::name;
            $filename =~ s!$BASEPATH/?!!;

            push @file_list, $File::Find::name;
        }
    }
}


__END__

=head1 NAME

getstrings.pl - Extract string or string-array from strings.xml to CSV.

=head1 SYNOPSIS

getstrings.pl [options]

 Options:
   -path <Base path>
   -out <Output file>
   -help
   -debug

=head1 OPTIONS

=over 8

=item B<-path>

Set the base path which you want to get strings.
Use current path when not specified.

=item B<-out>

Specified Output filename, use 'strings.csv' for defauilt.

=item B<-help>

Help.

=item B<-debug>

print debug when running.

=back

=head1 DESCRIPTION

B<getstrings.pl>

=cut

