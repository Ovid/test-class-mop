#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::MOP::Load qw(t/lib);

my $test_suite = Test::Class::MOP->new( show_timing => 0 );

my %methods_for = (
    'TestsFor::Basic'           => [qw/test_me test_this_baby/],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_me
          test_this_baby
          test_this_should_be_run
          /
    ],
);
my @test_classes = sort $test_suite->test_classes;
eq_or_diff \@test_classes, [ sort keys %methods_for ],
  'test_classes() should return a sorted list of test classes';

foreach my $class (@test_classes) {
    eq_or_diff [ $class->new->test_methods ], $methods_for{$class},
      "$class should have the correct test methods";
}

subtest 'test suite' => sub {
    $test_suite->runtests;
};

my $subclass_meta = mop::meta('TestsFor::Basic::Subclass');
$subclass_meta->add_method(
    $subclass_meta->method_class->new(
        name => 'test_this_will_die',
        body => sub { die 'forced die' },
    )
);
$subclass_meta->FINALIZE;

SKIP: {
    skip "Research how to attach meta/attributes via add_method()", 2;
    my $builder = $test_suite->test_configuration->builder;
    $builder->todo_start('testing a dying test');
    my @tests;
    $test_suite = Test::Class::MOP->new;
    subtest 'test_this_will_die() dies' => sub {
        $test_suite->runtests;
        @tests = $test_suite->test_configuration->builder->details;
    };
    $builder->todo_end;

    my @expected_tests = (
        {   'actual_ok' => 1,
            'name'      => 'TestsFor::Basic',
            'ok'        => 1,
            'reason'    => '',
            'type'      => ''
        },
        {   'actual_ok' => 0,
            'name'      => 'TestsFor::Basic::Subclass',
            'ok'        => 0,
            'reason'    => '',
            'type'      => ''
        }
    );

    eq_or_diff { tests => \@tests }, { tests => \@expected_tests },
      'Dying test methods should fail but not kill the test suite';
}

done_testing;
