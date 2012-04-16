#!/usr/bin/perl

use warnings;
use strict;
use Cwd;
use Getopt::Long;
use File::Find;
use XML::Parser;
use Text::CSV;

my $BASEPATH = getcwd;
my $OUTFILE = 'test/new.csv';
my $DEBUG = 0;
my $LANGUAGE = [
    'values',
];

GetOptions ('path=s' => \$BASEPATH, 'out=s' => \$OUTFILE, 'debug' => \$DEBUG);
print $BASEPATH."\n" if $DEBUG;
print $OUTFILE."\n" if $DEBUG;

-d $BASEPATH || die "$BASEPATH: $!\n";
$BASEPATH =~ s{(?<!/)$}{/};

my $prelang = join '|', @$LANGUAGE;
$prelang =~ s/(?=[.()])/\\/g;

my @file_list;
find(\&wanted, $BASEPATH);

open my $oh, "> ".$OUTFILE or die "$OUTFILE: $!";
my $csv = Text::CSV -> new({binary => 1, eol => $/}) or die "Cannot use CSV: ".Text::CSV -> error_diag ();
$csv -> eol("\r\n");
$csv -> print($oh, ['File path', 'name', 'value']);

my @out;
foreach my $file (@file_list) {
    open my $fh, "< $file" or warn "$file: $!" and next;
    my @file_content = <$fh>;
    close $fh;

    my $file_path = $file;
    $file_path =~ s/^$BASEPATH//;
    print $file."\n" if $DEBUG;

    my $filestring = join '', @file_content;
    while ($filestring =~ m{<string\s+name="(.*?)".*?>(.*?)</string.*?>}xsg) {
        my $sname = $1;
        my $svalue = $2;

        $csv -> print($oh, [$file_path, $sname, $svalue]);
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
