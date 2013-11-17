#!/usr/bin/env perl
use lib 'lib';
use Test::Most;
use Scalar::Util 'looks_like_number';
use Test::Class::MOP::Load qw(t/lib);
my $test_suite = Test::Class::MOP->new;

subtest 'run the test suite' => sub {
    $test_suite->runtests;
};
my $report = $test_suite->test_report;
explain $report->time->duration;

foreach my $class ( $report->all_test_classes ) {
    my $class_name = $class->name;
    ok !$class->is_skipped, "$class_name was not skipped";

    subtest "$class_name methods" => sub {
        foreach my $method ( $class->all_test_methods ) {
            my $method_name = $method->name;
            ok !$method->is_skipped, "$method_name was not skipped";
            cmp_ok $method->num_tests_run, '>', 0,
              '... and some tests should have been run';
            explain "Run time for $method_name: ".$method->time->duration;
        }
    };
    can_ok $class, 'time';
    my $time = $class->time;
    isa_ok $time, 'Test::Class::MOP::Report::Time', 
    '... and the object it returns';
    foreach my $method (qw/real user system/) {
        ok looks_like_number( $time->$method ),
          "... and its '$method()' method should return a number";
    }
    explain "Run time for $class_name: ".$time->duration;
}
explain "Number of test classes: " . $report->num_test_classes;
explain "Number of test methods: " . $report->num_test_methods;
explain "Number of tests:        " . $report->num_tests_run;

done_testing;
