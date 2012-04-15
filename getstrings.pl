#!/usr/bin/perl

use warnings;
use strict;
use Cwd;
use File::Find;
use XML::Parser;
use Text::CSV;

my $BASEPATH = @ARGV ? shift @ARGV : getcwd;
my $OUTFILE = 'test/new.csv';
my $LANGUAGE = [
    'values',
];

-d $BASEPATH || die "Cannot found path [$BASEPATH], $!\n";
$BASEPATH =~ s{(?<!/)$}{/};

my $prelang = join '|', @$LANGUAGE;
$prelang =~ s/(?=[.()])/\\/g;

my @file_list;
find(\&wanted, $BASEPATH);

open my $oh, ">:encoding(utf8)", $OUTFILE or die "$OUTFILE: $!";
my $csv = Text::CSV -> new({binary => 1, eol => $/}) or die "Cannot use CSV: ".Text::CSV -> error_diag ();
$csv -> eol("\r");
$csv -> print($oh, ['File path', 'name', 'value']);

foreach my $file (@file_list) {
    open my $fh, "< $file" or warn "Cannot open file [$file], $!" and next;
    my @file_content = <$fh>;
    close $fh;
    
    my $file_path = $file;
    $file_path =~ s/^$BASEPATH//;
    
    my $filestring = join '', @file_content;
    while ($filestring =~ m{<str\s+name="(.*?)".*?>.*?<val>(.*?)</val>.*?</str>}xsg) {
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