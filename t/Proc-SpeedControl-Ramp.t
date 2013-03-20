#!/usr/bin/perl
use lib 'lib';
use Test::More tests => 4;

use_ok('Proc::SpeedControl');

my $iter = 200;
my @args;
my $sc;

my @tests = (
    { interval => 60, rate => 420, batch =>  1, ramp =>  5 },
    { interval => 60, rate => 100, batch =>  1, ramp => 20 },
    { interval =>  1, rate =>  10, batch => 50, ramp => 10 },
);

for my $test (@tests) {
    @args = (
        interval => $test->{interval},
        rate => $test->{rate},
        ramp => $test->{ramp},
    );

    $sc = Proc::SpeedControl->new(@args);
    ok($sc, "created object $test->{rate}/$test->{interval} x $test->{batch} r:$test->{ramp}");

    $sc->_dump();
    $sc->did($test->{batch}) for 1..$iter;
    $sc->end();
    undef $sc;
}

exit;
