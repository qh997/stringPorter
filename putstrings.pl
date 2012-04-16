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

GetOptions (
    'path=s' => \$BASEPATH,
    'out=s'  => \$OUTFILE,
    'help|?' => \$HELP,
    'debug'  => \$DEBUG,
);

-d $BASEPATH || die "$BASEPATH: $!\n";
$BASEPATH =~ s{(?<!/)$}{/};

print "$BASEPATH\n" if $DEBUG;
print "$OUTFILE\n" if $DEBUG;

my $csv = Text::CSV -> new({binary => 1, eol => $/}) or die "Cannot use CSV: ".Text::CSV -> error_diag ();
#$csv -> eol("\r\n");

open my $oh, "< $OUTFILE" or die "$OUTFILE: $!";
my $title = <$oh>;
print $title."\n" if $DEBUG;

my %truck;
while (my $row = $csv -> getline($oh)) {
    if (@$row == 4) {
        my $path = shift @$row;
        my $type = shift @$row;
        my $name = shift @$row;
        my $value = shift @$row;

        print "$path:$type:$name:$value\n" if $DEBUG;

        $truck{$path} = {} unless exists $truck{$path};
        if ($type eq 'string') {
            $truck{$path} -> {$name} = $value; 
        }
        elsif ($type eq 'string-array') {
            $truck{$path} -> {$name} = [] unless exists ${$truck{$path}}{$name};
            push @{$truck{$path} -> {$name}}, $value;
        }
    }
}
close $oh;

print '=' x 40, "\n" if $DEBUG;
foreach my $path (keys %truck) {
    print $path."\n" if $DEBUG;

    open my $fh, "< $BASEPATH$path" or die "$path: $!";
    my @xmlfile = <$fh>;
    close $fh;
    my $xmlstr = join '', @xmlfile;

    foreach my $name (keys %{$truck{$path}}) {
        $xmlstr = put_strings($xmlstr, $path, $name, $truck{$path} -> {$name});
    }
#    print $xmlstr."\n";
}

sub put_strings {
    my $xml = shift;
    my $path = shift;
    my $name = shift;
    my $value = shift;

    print "\t\$name = $name\n" if 1||$DEBUG;

    if (ref $value eq 'ARRAY') {
        foreach my $item (@{$value}) {
            print "\t\t<item> $item\n" if $DEBUG;
        }
    }
    else {
        print "\t\t\$value = $value\n" if 1||$DEBUG;
        if ($xml =~ m{(?=<!--).*?(?<=-->).*?(<string[^>]*name="$name"[^>]*>)}s) {
            print "\$1 = $1\n";
            print "\$2 = $2\n";
            #$xml =~ s{((?:(?>(?=<!--).*?(?<=-->))|.*?).*?(<string[^>]*name="$name"[^>]*>)).*?(?=</string)}{$1$value}sg;
        }
        else {
            
        }
    }

    return $xml;
}
