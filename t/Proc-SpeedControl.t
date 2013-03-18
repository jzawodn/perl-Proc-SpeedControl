#!/usr/bin/perl
use lib 'lib';
use Test::More tests => 8;

use_ok('Proc::SpeedControl');

my $iter = 5;
my @args;
my $sc;

my @tests = (
    { interval => 60, rate => 120, batch =>  1 },
    { interval => 60, rate =>  10, batch =>  1 },
    { interval =>  1, rate => 100, batch =>  1 },
    { interval =>  1, rate => 100, batch => 50 },
    { interval => .1, rate =>   1, batch =>  2 },

    { interval => 'minute', rate =>  1000, batch =>  2 },
    { interval =>   'hour', rate => 10000, batch =>  4 },
);

for my $test (@tests) {
    @args = (
        interval => $test->{interval},
        rate => $test->{rate},
    );

    $sc = Proc::SpeedControl->new(@args);
    ok($sc, "created object $test->{rate}/$test->{interval} x $test->{batch}");

    $sc->_dump();
    $sc->did($test->{batch}) for 1..$iter;
    $sc->end();
    undef $sc;
}

exit;
