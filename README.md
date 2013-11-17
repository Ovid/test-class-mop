# NAME

Test::Class::Moose - Test::Class + Moose

# VERSION

version 0.22

# SYNOPSIS

    package TestsFor::DateTime;
    use Test::Class::Moose;
    use DateTime;

    # methods that begin with test_ are test methods.
    sub test_constructor {
        my ( $test, $report ) = @_;
        $report->plan(3);    # strictly optional

        can_ok 'DateTime', 'new';
        my %args = (
            year  => 1967,
            month => 6,
            day   => 20,
        );
        isa_ok my $date = DateTime->new(%args), 'DateTime';
        is $date->year, $args{year}, '... and the year should be correct';
    }

    1;

# DESCRIPTION

This is __BETA__ code. I encourage you to give it a shot if you want test
classes based on Moose, along with reporting. Feedback welcome as we try to
improve it.

This is a proof of concept for writing Test::Class-style tests with Moose.
Better docs will come later. You should already know how to use Moose and
[Test::Class](http://search.cpan.org/perldoc?Test::Class).

# BASICS

## Inheriting from Test::Class::Moose

Just `use Test::Class::Moose`. That's all. You'll get all [Test::Most](http://search.cpan.org/perldoc?Test::Most) test
functions, too, along with `strict` and `warnings`. You can use all [Moose](http://search.cpan.org/perldoc?Moose)
behavior, too.

## Declare a test method

All method names that begin with `test_` are test methods. Methods that do
not are not test methods.

    sub test_this_is_a_method {
        my $test = shift;

        $test->this_is_not_a_test_method;
        ok 1, 'whee!';
    }

    sub this_is_not_a_test_method {
       my $test = shift;
       # but you can, of course, call it like normal
    }

## Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit `done_testing` call.

If you prefer, you can declare a plan in a test method:

    sub test_something {
        my ( $test, $report ) = @_;
        $report->plan($num_tests);
        ...
    }

You may call `plan()` multiple times for a given test method. Each call to
`plan()` will add that number of tests to the plan.  For example, with a
method modifier:

    before 'test_something' => sub {
        my ( $test, $report ) = @_;
        $report->plan($num_extra_tests);

        # more tests
    };

Please note that if you call `plan`, the plan will still show up at the end
of the subtest run, but you'll get the desired failure if the number of tests
run does not match the plan.

## Inheriting from another Test::Class::Moose class

List it as the `extends` in the import list.

    package TestsFor::Some::Class::Subclass;
    use Test::Class::Moose extends => 'TestsFor::Some::Class';

    sub test_me {
        my $test  = shift;
        my $class = $test->test_class;
        ok 1, "I overrode my parent! ($class)";
    }

    before 'test_this_baby' => sub {
        my $test  = shift;
        my $class = $test->test_class;
        pass "This should run before my parent method ($class)";
    };

    sub this_should_not_run {
        my $test = shift;
        fail "We should never see this test";
    }

    sub test_this_should_be_run {
        for ( 1 .. 5 ) {
            pass "This is test number $_ in this method";
        }
    }

    1;

# TEST CONTROL METHODS

Do not run tests in test control methods. This will cause the test control
method to fail (this is a feature, not a bug).  If a test control method
fails, the class/method will fail and testing for that class should stop.

__Every__ test control method will be passed two arguments. The first is the
`$test` invocant. The second is an object implementing
[Test::Class::Moose::Role::Reporting](http://search.cpan.org/perldoc?Test::Class::Moose::Role::Reporting). You may find that the `notes` hashref
is a handy way of recording information you later wish to use if you call `$test_suite->test_report`.

These are:

- `test_startup`

    sub test_startup {
       my ( $test, $report ) = @_;
       $test->next::method;
       # more startup
    }

Runs at the start of each test class. If you need to know the name of the
class you're running this in (though usually you shouldn't), use
`$test->test_class`, or the `name` method on the `$report` object.

The `$report` object is a [Test::Class::Moose::Report::Class](http://search.cpan.org/perldoc?Test::Class::Moose::Report::Class) object.

- `test_setup`

    sub test_setup {
       my ( $test, $report ) = @_;
       $test->next::method;
       # more setup
    }

Runs at the start of each test method. If you must know the name of the test
you're about to run, you can call `$report->name`.

The `$report` object is a [Test::Class::Moose::Report::Method](http://search.cpan.org/perldoc?Test::Class::Moose::Report::Method) object.

- `test_teardown`

    sub test_teardown {
       my ( $test, $report ) = @_;
       # more teardown
       $test->next::method;
    }

Runs at the end of each test method. 

The `$report` object is a [Test::Class::Moose::Report::Method](http://search.cpan.org/perldoc?Test::Class::Moose::Report::Method) object.

- `test_shutdown`

    sub test_shutdown {
        my ( $test, $report ) = @_;
        # more teardown
        $test->next::method;
    }

Runs at the end of each test class. 

The `$report` object is a [Test::Class::Moose::Report::Class](http://search.cpan.org/perldoc?Test::Class::Moose::Report::Class) object.

To override a test control method, just remember that this is OO:

    sub test_setup {
        my  ( $test, $report ) = @_;
        $test->next::method; # optional to call parent test_setup
        # more setup code here
    }

# RUNNING THE TEST SUITE

We _strongly_ recommend using [Test::Class::Moose::Load](http://search.cpan.org/perldoc?Test::Class::Moose::Load) as the driver for
your test suite. Simply point it at the directory or directories containing
your test classes:

    use Test::Class::Moose::Load 't/lib';
    Test::Class::Moose->new->runtests;

By running `Test::Class::Moose` with a single driver script like this, all
classes are loaded once and this can be a significant performance boost. This
does mean a global state will be shared, so keep this in mind.

You can also pass arguments to `Test::Class::Moose`'s contructor.

    my $test_suite = Test::Class::Moose->new({
        show_timing => 1,
        randomize   => 0,
        statistics  => 1,
    });
    # do something
    $test_suite->runtests;

The attributes passed in the constructor are not directly available from the
[Test::Class::Moose](http://search.cpan.org/perldoc?Test::Class::Moose) instance. They're available in
[Test::Class::Moose::Config](http://search.cpan.org/perldoc?Test::Class::Moose::Config) and to avoid namespace pollution, we do _not_
delegate the attributes directly as a result. If you need them at runtime,
you'll need to access the `test_configuration` attribute:

    my $builder = $test_suite->test_configuration->builder;

## Contructor Attributes

- `show_timing`

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

- `statistics`

Boolean. Will display number of classes, test methods and tests run.

- `randomize`

Boolean. Will run test methods in a random order.

- `builder`

Defaults to `Test::Builder->new`. You can supply your own builder if you
want, but it must conform to the [Test::Builder](http://search.cpan.org/perldoc?Test::Builder) interface. We make no
guarantees about which part of the interface it needs.

- `test_classes`

Takes a class name or an array reference of class names. If it is present,
only these test classes will be run. This is very useful if you wish to run an
individual class as a test:

    Test::Class::Moose->new(
        test_classes => $ENV{TEST_CLASS}, # ignored if undef
    )->runtests;

You can also achieve this effect by writing a subclass and overriding the
`test_classes` method, but this makes it trivial to do this:

    TEST_CLASS=TestsFor::Our::Company::Invoice prove -lv t/test_classes.t

Alternatively:

    Test::Class::Moose->new(
        test_classes => \@ARGV, # ignored if empty
    )->runtests;

That lets you use the arisdottle to provide arguments to your test driver
script:

    prove -lv t/test_classes.t :: TestsFor::Our::Company::Invoice TestsFor::Something::Else

- `include`

Regex. If present, only test methods whose name matches `include` will be
included. __However__, they must still start with `test_`.

For example:

    my $test_suite = Test::Class::Moose->new({
        include => qr/customer/,
    });

The above constructor will let you match test methods named `test_customer`
and `test_customer_account`, but will not suddenly match a method named
`default_customer`.

By enforcing the leading `test_` behavior, we don't surprise developers who
are trying to figure out why `default_customer` is being run as a test. This
means an `include` such as `/^customer.*/` will never run any tests.

- `exclude`

Regex. If present, only test methods whose names don't match `exclude` will be
included. __However__, they must still start with `test_`. See `include`.

- `include_tags`

Array ref of strings matching method tags (a single string is also ok). If
present, only test methods whose tags match `include_tags` or whose tags
don't match `exclude_tags` will be included. __However__, they must still
start with `test_`.

For example:

    my $test_suite = Test::Class::Moose->new({
        include_tags => [qw/api database/],
    });

The above constructor will only run tests tagged with `api` or `database`.

- `exclude_tags`

The same as `include_tags`, but will exclude the tests rather than include
them. For example, if your network is down:

    my $test_suite = Test::Class::Moose->new({
        exclude_tags => [ 'network' ],
    });

    # or
    my $test_suite = Test::Class::Moose->new({
        exclude_tags => 'network',
    });

## Skipping Classes and Methods

If you wish to skip a class, set the reason in the `test_startup` method.

    sub test_startup {
        my ( $test, $report ) = @_;
        $test->test_skip("I don't want to run this class");
    }

If you wish to skip an individual method, do so in the `test_setup` method.

    sub test_setup {
        my ( $test, $report ) = @_;

        if ( 'test_time_travel' eq $report->name ) {
            $test->test_skip("Time travel not yet available");
        }
    }

## Tagging Methods

Sometimes you want to be able to assign metadata to help you better manage
your test suite. You can now do this with tags:

    sub test_save_poll_data : Tags(api network) {
        ...
    }

Tags are strictly optional and you can provide one or more tags for each test
method with a space separated list of tags. You can use this to filter your
tests suite, if desired. For example, if your network goes down and all tests
which rely on a network are tagged with `network`, you can skip those tests
with this:

    Test::Class::Moose->new( exclude_tags => 'network' )->runtests;

Or maybe you want to run all `api` and `database` tests, but skip those
marked `deprecated`:

    Test::Class::Moose->new(
        include_tags => [qw/api database/],
        exclude_tags => 'deprecated',
    )->runtests;

Tagging support relies on [Sub::Attribute](http://search.cpan.org/perldoc?Sub::Attribute). If this module is not available,
`include_tags` and `exclude_tags` will be ignored, but a warning will be
issued if those are seen.

Tagging support is relatively new and feature requests (and patches!) are
welcome.

# THINGS YOU CAN OVERRIDE

... but probably shouldn't.

As a general rule, methods beginning with `/^test_/` are reserved for
[Test::Class::Moose](http://search.cpan.org/perldoc?Test::Class::Moose). This makes it easier to remember what you can and
cannot override.

## `test_configuration`

    my $test_configuration = $test->test_configuration;

Returns the [Test::Class::Moose::Config](http://search.cpan.org/perldoc?Test::Class::Moose::Config) object.

## `test_report`

    my $report = $test->test_report;

Returns the [Test::Class::Moose::Report](http://search.cpan.org/perldoc?Test::Class::Moose::Report) object. Useful if you want to do
your own reporting and not rely on the default output provided with the
`statistics` boolean option.

## `test_class`

    my $class = $test->test_class;

Returns the name for this test class. Useful if you rebless an object (such as
applying a role at runtime) and don't want to lose the original class name.

## `test_classes`

You may override this in a subclass. Currently returns a sorted list of all
loaded classes that inherit directly or indirectly through
[Test::Class::Moose](http://search.cpan.org/perldoc?Test::Class::Moose)

## `test_methods`

You may override this in a subclass. Currently returns all methods in a test
class that start with `test_` (except for the test control methods).

Please note that the behavior for `include` and `exclude` is also contained
in this method. If you override it, you will need to account for those
yourself.

## `runtests`

If you really, really want to change how this module works, you can override
the `runtests` method. We don't recommend it.

Returns the [Test::Class::Moose](http://search.cpan.org/perldoc?Test::Class::Moose) instance.

## `import`

Sadly, we have an `import` method. This is used to automatically provide you
with all of the [Test::Most](http://search.cpan.org/perldoc?Test::Most) behavior.

# SAMPLE TAP OUTPUT

We use nested tests (subtests) at each level:

    1..2
    # 
    # Executing tests for TestsFor::Basic::Subclass
    # 
        1..3
        # TestsFor::Basic::Subclass->test_me()
            ok 1 - I overrode my parent! (TestsFor::Basic::Subclass)
            1..1
        ok 1 - test_me
        # TestsFor::Basic::Subclass->test_this_baby()
            ok 1 - This should run before my parent method (TestsFor::Basic::Subclass)
            ok 2 - whee! (TestsFor::Basic::Subclass)
            1..2
        ok 2 - test_this_baby
        # TestsFor::Basic::Subclass->test_this_should_be_run()
            ok 1 - This is test number 1 in this method
            ok 2 - This is test number 2 in this method
            ok 3 - This is test number 3 in this method
            ok 4 - This is test number 4 in this method
            ok 5 - This is test number 5 in this method
            1..5
        ok 3 - test_this_should_be_run
    ok 1 - TestsFor::Basic::Subclass
    # 
    # Executing tests for TestsFor::Basic
    # 
        1..2
        # TestsFor::Basic->test_me()
            ok 1 - test_me() ran (TestsFor::Basic)
            ok 2 - this is another test (TestsFor::Basic)
            1..2
        ok 1 - test_me
        # TestsFor::Basic->test_this_baby()
            ok 1 - whee! (TestsFor::Basic)
            1..1
        ok 2 - test_this_baby
    ok 2 - TestsFor::Basic
    # Test classes:    2
    # Test methods:    5
    # Total tests run: 11
    ok
    All tests successful.
    Files=1, Tests=2,  2 wallclock secs ( 0.03 usr  0.00 sys +  0.27 cusr  0.01 csys =  0.31 CPU)
    Result: PASS

# REPORTING

See [Test::Class::Moose::Report](http://search.cpan.org/perldoc?Test::Class::Moose::Report) for more detailed information on reporting.

Reporting features are subject to change.

Sometimes you want more information about your test classes, it's time to do
some reporting. Maybe you even want some tests for your reporting. If you do
that, run the test suite in a subtest (because the plans will otherwise be
wrong).

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::Moose::Load qw(t/lib);
    my $test_suite = Test::Class::Moose->new;

    subtest 'run the test suite' => sub {
        $test_suite->runtests;
    };
    my $report = $test_suite->test_report;

    foreach my $class ( $report->all_test_classes ) {
        my $class_name = $class->name;
        ok !$class->is_skipped, "$class_name was not skipped";

        subtest "$class_name methods" => sub {
            foreach my $method ( $class->all_test_methods ) {
                my $method_name = $method->name;
                ok !$method->is_skipped, "$method_name was not skipped";
                cmp_ok $method->num_tests, '>', 0,
                  '... and some tests should have been run';
                diag "Run time for $method_name: ".$method->time->duration;
            }
        };
        my $time   = $class->time;
        diag "Run time for $class_name: ".$class->time->duration;

        my $real   = $time->real;
        my $user   = $time->user;
        my $system = $time->system;
        # do with these as you will
    }
    diag "Number of test classes: " . $report->num_test_classes;
    diag "Number of test methods: " . $report->num_test_methods;
    diag "Number of tests:        " . $report->num_tests;

    done_testing;

If you just want to output reporting information, you do not need to run the
test suite in a subtest:

    my $test_suite = Test::Class::Moose->new->runtests;
    my $report     = $test_suite->test_report;
    ...

Or even shorter:

    my $report = Test::Class::Moose->new->runtests->test_report;

# EXTRAS

If you would like [Test::Class::Moose](http://search.cpan.org/perldoc?Test::Class::Moose) to take care of loading your classes
for you, see [Test::Class::Moose::Role::AutoUse](http://search.cpan.org/perldoc?Test::Class::Moose::Role::AutoUse) in this distribution.

# TODO

- Callbacks for tags (for example, 'critical' tags could bailout)
- New test phases - start and end suite, not just start and end class/method

# BUGS

Please report any bugs or feature requests to `bug-test-class-moose at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::Moose

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose)

- AnnoCPAN: Annotated CPAN documentation

[http://annocpan.org/dist/Test-Class-Moose](http://annocpan.org/dist/Test-Class-Moose)

- CPAN Ratings

[http://cpanratings.perl.org/d/Test-Class-Moose](http://cpanratings.perl.org/d/Test-Class-Moose)

- Search CPAN

[http://search.cpan.org/dist/Test-Class-Moose/](http://search.cpan.org/dist/Test-Class-Moose/)

# SEE ALSO

- [Test::Routine](http://search.cpan.org/perldoc?Test::Routine)

I always pointed people to this when they would ask about [Test::Class](http://search.cpan.org/perldoc?Test::Class) +
[Moose](http://search.cpan.org/perldoc?Moose), but I would always hear "that's not quite what I'm looking for".
I don't quite understand what the reasoning was, but I strongly encourage you
to take a look at [Test::Routine](http://search.cpan.org/perldoc?Test::Routine).

- [Test::Roo](http://search.cpan.org/perldoc?Test::Roo)

[Test::Routine](http://search.cpan.org/perldoc?Test::Routine), but with [Moo](http://search.cpan.org/perldoc?Moo) instead of [Moose](http://search.cpan.org/perldoc?Moose).

- [Test::Class](http://search.cpan.org/perldoc?Test::Class)

xUnit-style testing in Perl.

- [Test::Class::Most](http://search.cpan.org/perldoc?Test::Class::Most)

[Test::Class](http://search.cpan.org/perldoc?Test::Class) + [Test::Most](http://search.cpan.org/perldoc?Test::Most).

# ACKNOWLEDGEMENTS

Thanks to Tom Beresford (beresfordt) for spotting an issue when a class has no
test methods.

Thanks to Judioo for adding the randomize attribute.

Thanks to Adrian Howard for [Test::Class](http://search.cpan.org/perldoc?Test::Class).

# AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.