# NAME

Test::Class::MOP - Test::Class + MOP

# VERSION

version 0.22

# SYNOPSIS

    use mop;

    class TestsFor::DateTime extends Test::Class::MOP {
        use DateTime;
        use Test::Most;

        # methods that begin with test_ are test methods.
        method test_constructor($report) {
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
    }

# DESCRIPTION

This is __ALPHA__ code. I encourage you to give it a shot if you want test
classes based on MOP, along with reporting. Feedback welcome as we try to
improve it.

This is a proof of concept for writing Test::Class-style tests with
[https://github.com/stevan/p5-mop-redux](https://github.com/stevan/p5-mop-redux). Better docs will come later.

# BASICS

## Declare a test method

All method names that begin with `test_` are test methods. Methods that do
not are not test methods.

    class TestsFor::Some::Class extends Test::Class::MOP {
        use Test::Most;

     method test_this_is_a_method($report) {
         $self->this_is_not_a_test_method;
         ok 1, 'whee!';
     }

        method this_is_not_a_test_method {
           # but you can, of course, call it like normal
        }
    }

## Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit `done_testing` call.

If you prefer, you can declare a plan in a test method:

    method test_something($report) {
        $report->plan($num_tests);
        ...
    }

You may call `plan()` multiple times for a given test method. Each call to
`plan()` will add that number of tests to the plan.  For example, with an
overridden method:

    method test_something($report) {
        $self->next::method($report);
        $report->plan($num_extra_tests);
        # more tests
    };

Please note that if you call `plan`, the plan will still show up at the end
of the subtest run, but you'll get the desired failure if the number of tests
run does not match the plan.

## Inheriting from another Test::Class::MOP class

List it as `extends`, as you would expect.

    use mop;

    # assumes TestsFor::Some::Class inherits from Test::Class::MOP
    class TestsFor::Some::Class::Subclass extends TestsFor::Some::Class {
        use Test::Most;

     method test_me($report) {
         my $class = $self->test_class;
         ok 1, "I overrode my parent! ($class)";
     }

     method test_this_baby($report) {
         my $class = $self->test_class;
         pass "This should run before my parent method ($class)";
         $self->next::method($report);
     }

     method this_should_not_run {
         fail "We should never see this test";
     }

        method test_this_should_be_run($report) {
            for ( 1 .. 5 ) {
                pass "This is test number $_ in this method";
            }
        }
    }

# TEST CONTROL METHODS

Do not run tests in test control methods. This will cause the test control
method to fail (this is a feature, not a bug).  If a test control method
fails, the class/method will fail and testing for that class should stop.

__Every__ test control method will be passed two arguments. The first is the
`$self` invocant. The second is an object implementing
[Test::Class::MOP::Role::Reporting](https://metacpan.org/pod/Test::Class::MOP::Role::Reporting). You may find that the `notes` hashref
is a handy way of recording information you later wish to use if you call `$test_suite->test_report`.

These are:

- `test_startup`

        method test_startup($report) {
           $self->next::method($report);
           # more startup
        }

    Runs at the start of each test class. If you need to know the name of the
    class you're running this in (though usually you shouldn't), use
    `$self->test_class`, or the `name` method on the `$report` object.

    The `$report` object is a [Test::Class::MOP::Report::Class](https://metacpan.org/pod/Test::Class::MOP::Report::Class) object.

- `test_setup`

        method test_setup($report) {
           $self->next::method($report);
           # more setup
        }

    Runs at the start of each test method. If you must know the name of the test
    you're about to run, you can call `$report->name`.

    The `$report` object is a [Test::Class::MOP::Report::Method](https://metacpan.org/pod/Test::Class::MOP::Report::Method) object.

- `test_teardown`

        method test_teardown($report) {
           # more teardown
           $self->next::method($report);
        }

    Runs at the end of each test method. 

    The `$report` object is a [Test::Class::MOP::Report::Method](https://metacpan.org/pod/Test::Class::MOP::Report::Method) object.

- `test_shutdown`

        method test_shutdown($report) {
            # more teardown
            $self->next::method($report);
        }

    Runs at the end of each test class. 

    The `$report` object is a [Test::Class::MOP::Report::Class](https://metacpan.org/pod/Test::Class::MOP::Report::Class) object.

To override a test control method, just remember that this is OO:

    method test_setup($report) {
        $self->next::method($report); # optional to call parent test_setup
        # more setup code here
    }

# RUNNING THE TEST SUITE

We recommend using [Test::Class::MOP::Load](https://metacpan.org/pod/Test::Class::MOP::Load) as the driver for your test
suite. Simply point it at the directory or directories containing your test
classes:

    use Test::Class::MOP::Load 't/lib';
    Test::Class::MOP->new->runtests;

By running `Test::Class::MOP` with a single driver script like this, all
classes are loaded once and this can be a significant performance boost. This
does mean a global state will be shared, so keep this in mind.

You can also pass arguments to `Test::Class::MOP`'s contructor.

    my $test_suite = Test::Class::MOP->new({
        show_timing => 1,
        randomize   => 0,
        statistics  => 1,
    });
    # do something
    $test_suite->runtests;

The attributes passed in the constructor are not directly available from the
[Test::Class::MOP](https://metacpan.org/pod/Test::Class::MOP) instance. They're available in
[Test::Class::MOP::Config](https://metacpan.org/pod/Test::Class::MOP::Config) and to avoid namespace pollution, we do _not_
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
    want, but it must conform to the [Test::Builder](https://metacpan.org/pod/Test::Builder) interface. We make no
    guarantees about which part of the interface it needs.

- `test_classes`

    Takes a class name or an array reference of class names. If it is present,
    only these test classes will be run. This is very useful if you wish to run an
    individual class as a test:

        Test::Class::MOP->new(
            test_classes => $ENV{TEST_CLASS}, # ignored if undef
        )->runtests;

    You can also achieve this effect by writing a subclass and overriding the
    `test_classes` method, but this makes it trivial to do this:

        TEST_CLASS=TestsFor::Our::Company::Invoice prove -lv t/test_classes.t

    Alternatively:

        Test::Class::MOP->new(
            test_classes => \@ARGV, # ignored if empty
        )->runtests;

    That lets you use the arisdottle to provide arguments to your test driver
    script:

        prove -lv t/test_classes.t :: TestsFor::Our::Company::Invoice TestsFor::Something::Else

- `include`

    Regex. If present, only test methods whose name matches `include` will be
    included. __However__, they must still start with `test_`.

    For example:

        my $test_suite = Test::Class::MOP->new({
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

## Skipping Classes and Methods

If you wish to skip a class, set the reason in the `test_startup` method.

    method test_startup($report) {
        $self->test_skip("I don't want to run this class");
    }

If you wish to skip an individual method, do so in the `test_setup` method.

    method test_setup($report) {
        if ( 'test_time_travel' eq $report->name ) {
            $self->test_skip("Time travel not yet available");
        }
    }

# THINGS YOU CAN OVERRIDE

... but probably shouldn't.

As a general rule, methods beginning with `/^test_/` are reserved for
[Test::Class::MOP](https://metacpan.org/pod/Test::Class::MOP). This makes it easier to remember what you can and
cannot override.

## `test_configuration`

    my $test_configuration = $self->test_configuration;

Returns the [Test::Class::MOP::Config](https://metacpan.org/pod/Test::Class::MOP::Config) object.

## `test_report`

    my $report = $self->test_report;

Returns the [Test::Class::MOP::Report](https://metacpan.org/pod/Test::Class::MOP::Report) object. Useful if you want to do
your own reporting and not rely on the default output provided with the
`statistics` boolean option.

## `test_class`

    my $class = $self->test_class;

Returns the name for this test class. Useful if you rebless an object (such as
applying a role at runtime) and don't want to lose the original class name.

## `test_classes`

You may override this in a subclass. Currently returns a sorted list of all
loaded classes that inherit directly or indirectly through
[Test::Class::MOP](https://metacpan.org/pod/Test::Class::MOP)

## `test_methods`

You may override this in a subclass. Currently returns all methods in a test
class that start with `test_` (except for the test control methods).

Please note that the behavior for `include` and `exclude` is also contained
in this method. If you override it, you will need to account for those
yourself.

## `runtests`

If you really, really want to change how this module works, you can override
the `runtests` method. We don't recommend it.

Returns the [Test::Class::MOP](https://metacpan.org/pod/Test::Class::MOP) instance.

## `import`

Sadly, we have an `import` method. This is used to automatically provide you
with all of the [Test::Most](https://metacpan.org/pod/Test::Most) behavior.

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

See [Test::Class::MOP::Report](https://metacpan.org/pod/Test::Class::MOP::Report) for more detailed information on reporting.

Reporting features are subject to change.

Sometimes you want more information about your test classes, it's time to do
some reporting. Maybe you even want some tests for your reporting. If you do
that, run the test suite in a subtest (because the plans will otherwise be
wrong).

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::MOP::Load qw(t/lib);
    my $test_suite = Test::Class::MOP->new;

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

    my $test_suite = Test::Class::MOP->new->runtests;
    my $report     = $test_suite->test_report;
    ...

Or even shorter:

    my $report = Test::Class::MOP->new->runtests->test_report;

# EXTRAS

If you would like [Test::Class::MOP](https://metacpan.org/pod/Test::Class::MOP) to take care of loading your classes
for you, see [Test::Class::MOP::Role::AutoUse](https://metacpan.org/pod/Test::Class::MOP::Role::AutoUse) in this distribution.

# TODO

- New test phases - start and end suite, not just start and end class/method

# BUGS

Please report any bugs or feature requests to `bug-test-class-moose at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-MOP](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-MOP).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::MOP

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-MOP](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-MOP)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Test-Class-MOP](http://annocpan.org/dist/Test-Class-MOP)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Test-Class-MOP](http://cpanratings.perl.org/d/Test-Class-MOP)

- Search CPAN

    [http://search.cpan.org/dist/Test-Class-MOP/](http://search.cpan.org/dist/Test-Class-MOP/)

# SEE ALSO

- [Test::Routine](https://metacpan.org/pod/Test::Routine)

    I always pointed people to this when they would ask about [Test::Class](https://metacpan.org/pod/Test::Class) +
    [MOP](https://metacpan.org/pod/MOP), but I would always hear "that's not quite what I'm looking for".
    I don't quite understand what the reasoning was, but I strongly encourage you
    to take a look at [Test::Routine](https://metacpan.org/pod/Test::Routine).

- [Test::Roo](https://metacpan.org/pod/Test::Roo)

    [Test::Routine](https://metacpan.org/pod/Test::Routine), but with [Moo](https://metacpan.org/pod/Moo) instead of [MOP](https://metacpan.org/pod/MOP).

- [Test::Class](https://metacpan.org/pod/Test::Class)

    xUnit-style testing in Perl.

- [Test::Class::Most](https://metacpan.org/pod/Test::Class::Most)

    [Test::Class](https://metacpan.org/pod/Test::Class) + [Test::Most](https://metacpan.org/pod/Test::Most).

# ACKNOWLEDGEMENTS

Thanks to Tom Beresford (beresfordt) for spotting an issue when a class has no
test methods.

Thanks to Judioo for adding the randomize attribute.

Thanks to Adrian Howard for [Test::Class](https://metacpan.org/pod/Test::Class).

# AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
