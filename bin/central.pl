#!/usr/bin/env perl

use utf8;
use autodie;

use Modern::Perl;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::Dumper;
use English      qw/-no_match_vars/;
use GTFS         qw/gtfs_calendar gtfs_stop_times gtfs_trips/;
use Formatter    qw/tsv_body tsv_header/;
use Mojo::Loader qw/data_section/;
use Text::CSV    qw/csv/;

sub get_stations {
  my $csv = data_section( __PACKAGE__, 'stations.csv' );
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

sub main {
  binmode STDOUT, ':encoding(UTF-8)';
  binmode STDERR, ':encoding(UTF-8)';

  my $gtfs_dir = $FindBin::Bin . '/../gtfs';
  if ( !-d $gtfs_dir ) {
    die "$gtfs_dir is not a valid input directory\n";
  }
  $gtfs_dir =~ s/\/$//msx;

  my %calendar = gtfs_calendar($gtfs_dir);
  my @stations = get_stations();
  my %routes   = get_routes();

  say tsv_header( \@stations );

  foreach my $route_id ( keys %routes ) {
    my @trips      = gtfs_trips( $gtfs_dir, $route_id );
    my %stop_times = gtfs_stop_times( $gtfs_dir, @trips );

    say tsv_body( $routes{$route_id}, \%calendar, \@stations, \@trips, \%stop_times );
  }

  exit 0;
}

main();

__DATA__

@@ routes.csv
16448_109,a
16449_109,b
24609_109,bx
16451_109,c
16452_109,e
16454_109,h

@@ stations.csv
8600634,Dybbølsbro,0.0
8600626,København H,0.9
8600645,Vesterport,1.4
8600646,Nørreport,2.4
8600650,Østerport,4.0
8600653,Nordhavn,5.4
8600654,Svanemøllen,6.7
