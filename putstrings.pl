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
my $SHOW_CHN = 0;
my $DEBUG = 0;

GetOptions (
    'path=s' => \$BASEPATH,
    'in=s'  => \$OUTFILE,
    'help|?' => \$HELP,
    'show-changes'  => \$SHOW_CHN,
    'debug'  => \$DEBUG,
) or pod2usage(2);

if ($HELP) {
    pod2usage(1);
    exit 0;
}

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
my %type;
my $line = 1;
while (my $row = $csv -> getline($oh)) {
    $line++;
    if (@$row == 5) {
        my $path = shift @$row;
        my $type = shift @$row;
        my $name = shift @$row;
        my $value = shift @$row;
        my $pw_edits = shift @$row;

        next unless ($pw_edits);
        if ($pw_edits eq $value) {
            warn "[WARNING] Line $line : no change!\n";
            next;
        }
        elsif (!-e $BASEPATH.$path) {
            warn "[ERROR] Line $line : $path cannot found!\n";
            next;
        }
        print "Line $line will be replacing.\n" if $SHOW_CHN;
        print "$path:$type:$name:$value:$pw_edits\n" if $DEBUG;

        $type{$path, $name} = $type;
        print $type{$path, $name}."\n" if $DEBUG;

        $truck{$path} = {} unless exists $truck{$path};
        if ($type eq 'string-array') {
            push @{$truck{$path}->{$name}}, $pw_edits;
        }
        else {
            $truck{$path}->{$name} = $pw_edits;
        }
    }
}
close $oh;

print '=' x 40, "\n" if $DEBUG;
foreach my $path (keys %truck) {
    print "Write in $path\n";

    open my $fh, "< $BASEPATH$path" or warn "$path: $!";
    my @xmlfile = <$fh>;
    close $fh;
    my $xmlstr = join '', @xmlfile;

    foreach my $name (keys %{$truck{$path}}) {
        $xmlstr = put_strings($xmlstr, $path, $name, $truck{$path}->{$name}, $type{$path, $name});
    }

    open my $oh, "> $BASEPATH$path" or warn "$path: $!";
    print $oh $xmlstr;
    close $oh;
}

sub put_strings {
    my $xml = shift;
    my $path = shift;
    my $name = shift;
    my $value = shift;
    my $type = shift;

    print "\t\$name = $name\n" if $DEBUG;

    if (ref $value eq 'ARRAY') {
        for (my $i = 0; $i < @{$value}; $i++) {
            print "\t\t<item> ${$value}[$i]\n" if $DEBUG;
            my $j = @{$value} - $i;
            
            if ($xml =~ s{
                    (<$type[^>]*name="$name"[^>]*>
                     .*?
                     (?:<item>.*?</item>.*?){$i})
                    (?<=<item>).*?(?=</item>)
                    }{$1${$value}[$i]}xgs) {
                print "Put item in <$name>.\n" if $DEBUG;
            }
            else {
                warn "Cannot put <$name> with item <${$value}[$i]> in [$path].\n";
            }
        }
    }
    else {
        print "\t\t\$type = $type\n" if $DEBUG;
        print "\t\t\$value = $value\n" if $DEBUG;
        if ($xml =~ s{(<$type[^>]*name="$name"[^>]*>).*?(?=</$type)}{$1$value}sg) {
            print "Put string <$name>.\n" if $DEBUG;
        }
        else {
            warn "[ERROR] Cannot found <$name> in [$path]!\n";
        }
    }

    return $xml;
}


__END__

=head1 NAME

putstrings.pl - Write string or string-array from CSV to strings.xml.

=head1 SYNOPSIS

putstrings.pl [options]

 Options:
   -path <Base path>
   -in <input file>
   -help
   -show-changes
   -debug

=head1 OPTIONS

=over 8

=item B<-path>

Set the base path which you want to put strings.
Use current path when not specified.

=item B<-out>

Specified Output filename, use 'strings.csv' for defauilt.

=item B<-help>

Help.

=item B<-show-changes>

Lists the line number of the line in the scv file that will be replaced.

=item B<-debug>

print debug when running.

=back

=head1 DESCRIPTION

B<getstrings.pl>

=cut

