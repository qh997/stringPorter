#!/usr/bin/perl

use warnings;
use strict;
use File::Find;

my $BASEPATH = @ARGV ? shift @ARGV : '/home/gengs/amazon/ics_mr1';
my $LANGUAGE = [
    'values',
];

my $prelang = join '|', @$LANGUAGE;
$prelang =~ s/(?=[.()])/\\/g;

my @file_list;
find(\&wanted, $BASEPATH);

sub wanted {
    if (-f $File::Find::name) {
        if ($File::Find::name =~ m{/$prelang/strings\.xml$}) {
            my $basepath = $BASEPATH;
            $basepath =~ s/(?=[.()])/\\/g;

            my $filename = $File::Find::name;
            $filename =~ s!$BASEPATH/?!!;

            push @file_list, $File::Find::name;
            print $BASEPATH.'/'.$filename."\n";
        }
    }
}
