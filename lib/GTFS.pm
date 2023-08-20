package GTFS;

use Modern::Perl;
use English qw/-no_match_vars/;

use parent qw/Exporter/;

our @EXPORT_OK = qw/gtfs_calendar gtfs_stop_times gtfs_trips/;

sub gtfs_calendar {
  my ($dir) = @_;

  open my $in, '<', $dir . '/calendar.txt' or die "Unable to open 'calendar.txt': $ERRNO\n";

  my %calendar;
  while (<$in>) {
    chomp;
    my @parts = split /,/msx;

    my $days = q{};

    $days .= 'M' if $parts[1];
    $days .= 'T' if $parts[2];
    $days .= 'W' if $parts[3];
    $days .= 'R' if $parts[4];
    $days .= 'F' if $parts[5];
    $days .= 'S' if $parts[6];
    $days .= 'U' if $parts[7];

    $calendar{ $parts[0] } = $days;
  }

  close $in or die "Unable to close file 'calendar.txt': $ERRNO\n";

  return %calendar;
}

sub gtfs_trips {
  my ( $dir, $route_id ) = @_;
  my @trips;

  open my $in, '<', $dir . '/trips.txt' or die "Unable to open 'trips.txt': $ERRNO\n";

  while (<$in>) {
    if ( !/^"$route_id"/msx ) {
      next;
    }

    my @parts = split /,/msx;

    push @trips, {
      direction_id => 0 + $parts[5],
      service_id   => 0 + $parts[1],
      trip_id      => 0 + $parts[2],
    };
  }

  close $in or die "Unable to close file 'trips.txt': $ERRNO\n";

  return @trips;
}

sub gtfs_stop_times {
  my ( $dir, @trips ) = @_;
  my %stop_times;

  my %trips = map { $_->{trip_id} => 1 } @trips;

  open my $in, '<:encoding(UTF-8)', $dir . '/stop_times.txt' or die "Unable to open 'stop_times.txt': $ERRNO\n";

  while (<$in>) {
    my @parts = split /,/smx;

    if ( !exists $trips{ $parts[0] } ) {
      next;
    }

    if ( $parts[5] != 0 or $parts[6] != 0 ) {
      next;
    }

    my $trip_id = $parts[0];

    if ( !exists $stop_times{$trip_id} ) {
      $stop_times{$trip_id} = [];
    }

    push @{ $stop_times{$trip_id} }, {
      departure_time => $parts[2],
      stop_id        => $parts[3] + 0,
    };
  }

  close $in or die "Unable to close file 'stop_times.txt': $ERRNO\n";

  return %stop_times;
}

1;
