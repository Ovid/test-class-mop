#!/usr/bin/env perl
use Test::Most;
use Benchmark 'timediff';
use Test::Class::MOP::Report::Time;

my $start = Benchmark->new;
sleep 3;
my $time = Test::Class::MOP::Report::Time->new(
    timediff => timediff(
        Benchmark->new,
        $start
    )
);
isa_ok $time, 'Test::Class::MOP::Report::Time';
like $time->duration, qr/\d.*wallclock/,
  'duration() should return a human-readable string';
like $time->real, qr/\d\.\d+/, 'real() should return the real time';
can_ok $time, $_ foreach qw/user system/;

done_testing;
