#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::MOP::Load 't/lib';

# I find it annoying that the various testing modules for testing have failed
# me completely here.

my $tests = Test::Class::MOP->new(
    {   show_timing => 0,
        statistics  => 1,
    }
);
my $builder = $tests->test_configuration->builder;

#
# exceptions in test control methods should cause the test classes to fail
#
my $subclass_meta = mop::meta('TestsFor::Basic::Subclass');
$subclass_meta->add_method(
    $subclass_meta->method_class->new(
        name => 'test_startup',
        body => sub { die 'forced die' },
    )
);
$subclass_meta->FINALIZE;
$builder->todo_start('testing the startup() method');
my @tests;
subtest 'test_startup() dies' => sub {
    $tests->runtests;
    @tests = $tests->test_configuration->builder->details;
};
$builder->todo_end;

my @expected = (
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
    },
);

eq_or_diff { result => $tests[1] }, { result => $expected[1] },
  'Our subclass should fail if tests are run in the test control methods';
eq_or_diff { result => $tests[0] }, { result => $expected[0] },
  '... but its parent class should succeed because it does not have tests in the startup';

#
# test control methods that live and have no tests should not cause issues
#
@expected = (
    {   'actual_ok' => 1,
        'name'      => 'TestsFor::Basic',
        'ok'        => 1,
        'reason'    => '',
        'type'      => ''
    },
    {   'actual_ok' => 1,
        'name'      => 'TestsFor::Basic::Subclass',
        'ok'        => 1,
        'reason'    => '',
        'type'      => ''
    },
);
$subclass_meta->remove_method('test_startup');
$subclass_meta->add_method(
    $subclass_meta->method_class->new(
        name => 'test_startup',
        body => sub { my $test = shift },
    )
);
$subclass_meta->FINALIZE;
$tests = Test::Class::MOP->new;
subtest 'test_startup() has tests in it' => sub {
    $tests->runtests;
    @tests = $tests->test_configuration->builder->details;
};

eq_or_diff { result => \@tests }, { result => \@expected },
  'Test control methods that do not misbehave should not fail';

#
# tests in test control methods should cause the test classes to fail
#
@expected = (
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
    },
);
$subclass_meta->remove_method('test_startup');
$subclass_meta->add_method(
    $subclass_meta->method_class->new(
        name => 'test_setup',
        body => sub {
            my ( $test, $method ) = @_;
            my $name = $method->name;
            explain "About to run $name";
            pass();
        },
    )
);
$subclass_meta->FINALIZE;
$builder->todo_start('fail?');
$tests = Test::Class::MOP->new;
subtest 'test_setup() has tests in it' => sub {
    $tests->runtests;
    @tests = $tests->test_configuration->builder->details;
};
$builder->todo_end;

eq_or_diff { result => $tests[0] }, { result => $expected[0] },
  'Our first test class should fail if tests are run in the test control methods';
eq_or_diff { result => $tests[1] }, { result => $expected[1] },
  '... but its parent class should succeed because it does not have tests in the startup';

eval <<'END';
use mop;
class Any::Class extends Test::Class::MOP {
    method test_startup($report) is testcase {}
}
END

my $error = $@;
like $error,
  qr/^Test control methods may not use a testcase trait: Any::Class->test_startup/,
  'Applying the testcase trait to a test control method should be fatal';

done_testing;
