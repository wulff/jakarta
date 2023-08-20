package Formatter;

use Modern::Perl;
use English qw/-no_match_vars/;

use parent qw/Exporter/;

our @EXPORT_OK = qw/tsv_body tsv_header/;

sub tsv_header {
  my ($stations) = @_;

  my @header = qw/number type direction days/;

  foreach my $station ( @{$stations} ) {
    my @label;

    push @label, 'stop';
    push @label, $station->{name};
    push @label, $station->{distance};
    push @label, 0;

    push @header, join q{|}, @label;
  }

  return join "\t", @header;
}

sub tsv_body {
  my ( $line, $calendar, $stations, $trips, $stop_times ) = @_;

  my @rows = ();

  foreach my $trip ( @{$trips} ) {
    my $days = $calendar->{ $trip->{service_id} };
    if ( !$days ) {
      next;
    }

    my @row;

    push @row, $trip->{trip_id};
    push @row, uc $line;
    push @row, $trip->{direction_id} ? 'N' : 'S';
    push @row, $days;

    my %departures = ();
    foreach my $stop_time ( @{ $stop_times->{ $trip->{trip_id} } } ) {
      $departures{ $stop_time->{stop_id} } = $stop_time->{departure_time};
    }

    foreach my $station ( @{$stations} ) {
      if ( exists $departures{ $station->{id} } ) {
        my @time_parts = split /:/msx, $departures{ $station->{id} };
        push @row, sprintf '%02d:%02d', $time_parts[0], $time_parts[1];
      }
      else {
        push @row, q{-};
      }
    }

    push @rows, join "\t", @row;
  }

  return join "\n", @rows;
}

1;
