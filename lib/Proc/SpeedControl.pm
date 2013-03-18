package Proc::SpeedControl;

use 5.010000;
use strict;
use warnings;
use Time::HiRes qw(usleep gettimeofday tv_interval sleep);

our $VERSION = '0.01';

sub new {
    my ($class, @args) = @_;
    my $self = { @args };
    bless $self, $class;
    $self->init();
    return $self;
}

sub init {
    my ($self, @args) = @_;
    $self->{rate} ||= 1;
    $self->{interval} ||= 1;

    if ($self->{interval} eq 'minute') {
        $self->{interval} = 60;
    }
    elsif ($self->{interval} eq 'hour') {
        $self->{interval} = 60 * 60;
    }
    elsif ($self->{interval} eq 'day') {
        $self->{interval} = 60 * 60 * 24;
    }
    elsif ($self->{interval} eq 'week') {
        $self->{interval} = 60 * 60 * 24 * 7;
    }

    $self->{target} = ($self->{rate} / $self->{interval});
    $self->{default_work_done} ||= 1;
    $self->{total_work_done} ||= 0;
    $self->{last_sleep} ||= 1;
    $self->log("target: $self->{target}");
    return $self;
}

sub start {
    my ($self, @args) = @_;
    my $now = [gettimeofday()];
    $self->{first_run} = $now;
    $self->{last_run} = $now;
    $self->{sleep_count} = 0;
    $self->{average_sleep} = 1;
    return $self;
}

sub end {
    my ($self, @args) = @_;
    delete $self->{first_run};
    delete $self->{last_run};
    $self->log("$self->{sleep_count} total sleeps, averaging $self->{average_sleep}, work done: $self->{total_work_done}");
    return $self;
}

sub _compute_sleep {
    my ($self, $work_done) = @_;

    if (not $self->{first_run}) {
        $self->start();
        return 1;
    }

    my $now = [gettimeofday()];
    my $elapsed = tv_interval($self->{last_run}, $now);
    my $achieved = $work_done / $elapsed;
    my $mult = $achieved / $self->{target};

    # If $mult < 1 then we need to decrease the sleep by $mult
    #
    # If $mult > 1 then we need to increase the sleep by $mult
    #
    # If $mult is 1 then we're good to go

    $self->log("elapsed: $elapsed, achieved: $achieved, target: $self->{target}, mult: $mult");

    my $sleep = $self->{last_sleep} * $mult;

    $self->{last_sleep} = $sleep;
    $self->{total_work_done} += $work_done;
    $self->{last_run} = $now;
    $self->{sleep_count}++;
    $self->{average_sleep} = (($self->{average_sleep} * ($self->{sleep_count}-1)) + $self->{last_sleep}) / $self->{sleep_count};
    return $sleep;
}

sub did {
    my ($self, $work_done) = @_;
    $work_done ||= $self->{default_work_done};
    my $sleep = $self->_compute_sleep($work_done);
    if ($sleep) {
        $self->log("sleeping for $sleep");
        sleep $sleep;
    }
    return $sleep;
}

sub log {
    my ($self, @message) = @_;
    if ($self->{logger}) {
        $self->{logger}->info(@message);
    } else {
        if ($ENV{DEBUG}) {
            print join ' ', @message, "\n";
        }
    }
    return $self;
}

sub _dump {
    my ($self) = @_;
    while (my ($k, $v) = each %$self) {
        $self->log("$k: $v");
    }
}

1;
__END__

=head1 NAME

Proc::SpeedControl - controlling the rate at which things happen.

=head1 SYNOPSIS

  use Proc::SpeedControl;

  # max speed is 10 per second
  my $sc = Proc::SpeedControl->new(rate => 10, interval => 1);

  ...

  $sc->start(); # optional
  while (1) {
    do_work();
    $sc->did(1); # we did 1 unit of work. this may block for a bit
  }
  $sc->end(); # optional

=head1 DESCRIPTION

This module is meant to be used inside of a processing loop where
you'd like the regulate the rate at which work is performed.  It also
has an optional ramp-up feature so that the rate is initially slow and
increases until reaching the desired rate (if possible).

The initial use case is one where a process is able to run far faster
than is necessary and allowing it to do so could saturate an external
resource (such as a database).  This module handles computing how long
to sleep between iterations of the processing loop.

When you initialized an instance of Proc::SpeedControl, you supply two
paramenters:

  * rate
  * interval

The "rate" value is the amount of work you'd like done per "interval"
in seconds.  It's possible to use floating point values for both
arguments.  At initialization time, the values are used to compute a
"target" rate in terms of "work per second" which is what the code
uses for deciding how long (if at all) to sleep before allowing work
to continue.

One consequence of that, is that all of the following are equivalent
ways of saying "2 per second":

  * rate =>   2, interval => 1
  * rate =>  10, interval => 5
  * rate => 120, interval => 60

For the sake of convenience, the "interval" parameter may one of the
following strings (values in parenthesis are the actual values that
will be substituted):

  * minute (60)
  * hour (60*60)
  * day (60*60*24)
  * week (60*60*24*7)

So it is permissiable to specify something like this:

  * rate => 300, interval => 'minute'

And you'll get roughly 300 per minute.

=head2 EXPORT

None by default.

=head1 BUGS

This module doesn't maintain any sort of history of how well it tracks
to the target rate.  Doing so could be useful in some circumstances.

=head1 SEE ALSO

The source for this module lives on github:

  https://github.com/jzawodn/perl-Proc-SpeedControl

=head1 AUTHOR

Jeremy Zawodny, E<lt>Jeremy@Zawodny.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jeremy Zawodny

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
