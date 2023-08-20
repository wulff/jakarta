#!/usr/bin/env perl

use utf8;
use autodie;

use Modern::Perl;

use FindBin;
use lib "$FindBin::Bin/../lib";

use English      qw/-no_match_vars/;
use GTFS         qw/gtfs_calendar gtfs_stop_times gtfs_trips/;
use Formatter    qw/tsv_body tsv_header/;
use Mojo::Loader qw/data_section/;
use Pod::Usage;
use Text::CSV qw/csv/;

sub get_stations {
  my ($line) = @_;

  $line = 'a' if $line eq 'e';
  $line = 'b' if $line eq 'bx';
  $line = 'c' if $line eq 'h';

  my $file_name = $line . '.csv';

  my $csv = data_section( __PACKAGE__, $file_name );
  chomp $csv;

  my $aoa = csv( in => \$csv );

  my @stations;

  foreach my $row ( @{$aoa} ) {
    push @stations, {
      id       => $row->[0],
      name     => $row->[1],
      distance => $row->[2],
    };
  }

  return @stations;
}

sub get_routes {
  my $csv = data_section( __PACKAGE__, 'routes.csv' );
  chomp $csv;

  my $aoa = csv( in => \$csv, skip_empty_rows => 1 );

  my %routes;

  foreach my $row ( @{$aoa} ) {
    $routes{ $row->[0] } = $row->[1];
  }

  return %routes;
}

sub main() {
  binmode STDOUT, ':encoding(UTF-8)';
  binmode STDERR, ':encoding(UTF-8)';

  if ( !@ARGV ) {
    pod2usage(1);
  }

  my $line = lc shift @ARGV;

  my $gtfs_dir = $FindBin::Bin . '/../gtfs';
  if ( !-d $gtfs_dir ) {
    die "$gtfs_dir is not a valid input directory\n";
  }
  $gtfs_dir =~ s/\/$//msx;

  my %calendar = gtfs_calendar($gtfs_dir);
  my @stations = get_stations($line);

  my %routes     = get_routes();
  my @trips      = gtfs_trips( $gtfs_dir, $routes{$line} );
  my %stop_times = gtfs_stop_times( $gtfs_dir, @trips );

  say tsv_header( \@stations );
  say tsv_body( $line, \%calendar, \@stations, \@trips, \%stop_times );

  exit 0;
}

main();

__DATA__

@@ routes.csv
a,16448_109
b,16449_109
bx,24609_109
c,16451_109
e,16452_109
f,16453_109
h,16454_109

@@ a.csv
8600803,Køge,0
8600792,Ølby,2.7
8600797,Køge Nord,4.9
8600791,Jersie,8.2
8600790,Solrød Strand,9.7
8600771,Karlslunde,14.7
8600770,Greve,17.2
8600769,Hundige,20.3
8600768,Ishøj,22.6
8600767,Vallensbæk,24.9
8600766,Brøndby Strand,27.1
8600765,Avedøre,29.3
8600764,Friheden,31.2
8600763,Åmarken,32.7
8600783,Ny Ellebjerg,34.6
8600761,Sjælør,35.2
8600760,Sydhavn,36.1
8600634,Dybbølsbro,38.1
8600626,København H,39.0
8600645,Vesterport,39.5
8600646,Nørreport,40.5
8600650,Østerport,42.0
8600653,Nordhavn,43.5
8600654,Svanemøllen,44.8
8600655,Hellerup,46.8
8600672,Bernstorffsvej,48.3
8600673,Gentofte,49.9
8600674,Jægersborg,51.5
8600675,Lyngby,52.9
8600636,Sorgenfri,54.7
8600676,Virum,56.7
8600677,Holte,57.9
8600678,Birkerød,62.8
8600909,Høvelte,65.3
8600681,Allerød,68.3
8600683,Hillerød,75.5

@@ b.csv
8600798,Høje Taastrup,0.0
8600620,Taastrup,1.5
8600621,Albertslund,5.4
8600622,Glostrup,8.3
8600679,Brøndbyøster,11.0
8600680,Rødovre,12.1
8600600,Hvidovre,13.2
8600742,Danshøj,14.2
8600624,Valby,15.6
8600631,Carlsberg,17.0
8600634,Dybbølsbro,18.6
8600626,København H,19.5
8600645,Vesterport,20.0
8600646,Nørreport,21.0
8600650,Østerport,22.6
8600653,Nordhavn,24.0
8600654,Svanemøllen,25.3
8600644,Ryparken,31.5
8600688,Emdrup,34.3
8600780,Dyssegård,35.7
8600689,Vangede,36.6
8600781,Kildebakke,37.8
8600690,Buddinge,38.9
8600691,Stengården,40.7
8600692,Bagsværd,41.9
8600693,Skovbrynet,43.3
8600694,Hareskov,45.3
8600695,Værløse,48.3
8600696,Farum,52.4

@@ c.csv
8600714,Frederikssund,0.0
8600713,Vinge,4.6
8600712,Ølstykke,7.8
8600956,Egedal,10.3
8600711,Stenløse,11.8
8600710,Veksø,15.6
8600955,Kildedal,18.7
8600709,Måløv,20.8
8600708,Ballerup,24.0
8600756,Malmparken,25.8
8600707,Skovlunde,26.8
8600706,Herlev,29.5
8600705,Husum,31.1
8600704,Islev,32.4
8600734,Jyllingevej,33.6
8600703,Vanløse,34.5
8600736,Flintholm,35.2
8600702,Peter Bangs Vej,35.9
8600701,Langgade,37.0
8600624,Valby,37.9
8600631,Carlsberg,39.3
8600634,Dybbølsbro,40.9
8600626,København H,41.8
8600645,Vesterport,42.3
8600646,Nørreport,43.3
8600650,Østerport,44.9
8600653,Nordhavn,46.3
8600654,Svanemøllen,47.6
8600655,Hellerup,49.7
8600657,Charlottenlund,52.1
8600658,Ordrup,53.4
8600659,Klampenborg,55.2

@@ f.csv
8600783,Ny Ellebjerg,0.0
8600804,Vigerslev Allé,1.1
8600742,Danshøj,1.8
8600741,Ålholm,2.6
8600740,KB Hallen,3.3
8600736,Flintholm,4.3
8600641,Grøndal,5.5
8600640,Fuglebakken,6.4
8600642,Nørrebro,7.4
8600739,Bispebjerg,8.0
8600644,Ryparken,9.7
8600655,Hellerup,11.7

__END__

=head1 NAME

timetable.pl - Extract timetable for a specific route from GTFS data.

=head1 SYNOPSIS

timetable.pl [line]

=head1 DESCRIPTION

Prints the timetable in TSV format to STDOUT.

=head1 ARGUMENTS

=over 4

=item B<line>

The S-train line name, e.g. "A".

=back

=head1 AUTHOR

Morten Wulff <wulff@ratatosk.net>

=head1 COPYRIGHT

Copyright 2023 Morten Wulff

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
