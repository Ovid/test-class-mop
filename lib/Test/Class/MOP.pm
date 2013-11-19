# PODNAME: Test::Class::MOP
# ABSTRACT: Test::Class + MOP

# package declaration required due to this bug:
# https://github.com/stevan/p5-mop-redux/issues/147
package main;
use 5.016;
use strict;
use warnings;
use mop;
use Carp;
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);

use Test::Builder;
use Test::Most;
use Try::Tiny;
use Test::Class::MOP::Meta;
use Test::Class::MOP::Config;
use Test::Class::MOP::Report;
use Test::Class::MOP::Report::Class;
use Test::Class::MOP::Report::Method;

class Test::Class::MOP meta TestClassMeta {
    has $!test_configuration is ro;
    has $!test_class         is rw;
    has $!test_report        is ro = Test::Class::MOP::Report->new;
    has $!test_skip          is rw;
    method test_skip_clear { undef $!test_skip }

    method new ($class: @args) {
        $class->next::method(
            test_configuration => Test::Class::MOP::Config->new(@args) 
        );
    }

    method BUILD {
        # stash that name lest something change it later. Paranoid?
        $self->test_class( mop::meta($self)->name );
    }

    my $TEST_CONTROL_METHODS = sub {
        local *__ANON__ = 'ANON_TEST_CONTROL_METHODS';
        return {
            map { $_ => 1 }
              qw/
              test_startup
              test_setup
              test_teardown
              test_shutdown
              /
        };
    };

    my $RUN_TEST_CONTROL_METHOD = sub {
        local *__ANON__ = 'ANON_RUN_TEST_CONTROL_METHOD';
        my ( $self, $phase, $report_object ) = @_;

        $TEST_CONTROL_METHODS->()->{$phase}
          or croak("Unknown test control method ($phase)");

        my $success;
        my $builder = $self->test_configuration->builder;
        try {
            my $num_tests = $builder->current_test;
            $self->$phase($report_object);
            if ( $builder->current_test ne $num_tests ) {
                croak("Tests may not be run in test control methods ($phase)");
            }
            $success = 1;
        }
        catch {
            my $error = $_;
            my $class = $self->test_class;
            $builder->diag("$class->$phase() failed: $error");
        };
        return $success;
    };

    my $RUN_TEST_METHOD = sub {
        local *__ANON__ = 'ANON_RUN_TEST_METHOD';
        my ( $self, $test_instance, $test_method ) = @_;

        my $test_class = $test_instance->test_class;
        my $report  = Test::Class::MOP::Report::Method->new(
            { name => $test_method } );

        my $builder = $self->test_configuration->builder;
        $test_instance->test_skip_clear;
        $test_instance->$RUN_TEST_CONTROL_METHOD(
            'test_setup',
            $report
        );
        my $num_tests;

        Test::Most::explain("$test_class->$test_method()");
        $builder->subtest(
            $test_method,
            sub {
                if ( my $message = $test_instance->test_skip ) {
                    $report->skipped($message);
                    $builder->plan( skip_all => $message );
                    return;
                }
                $report->_start_benchmark;

                my $old_test_count = $builder->current_test;
                try {
                    $test_instance->$test_method($report);
                    if ( $report->has_plan ) {
                        $builder->plan( tests => $report->tests_planned );
                    }
                }
                catch {
                    fail "$test_method failed: $_";
                };
                $num_tests = $builder->current_test - $old_test_count;

                $report->_end_benchmark;
                if ( $self->test_configuration->show_timing ) {
                    my $time = $report->time->duration;
                    $self->test_configuration->builder->diag(
                        $report->name . ": $time" );
                }
            },
        );
        $test_instance->$RUN_TEST_CONTROL_METHOD(
            'test_teardown',
            $report
        );
        $self->test_report->current_class->add_test_method($report);
        if ( !$report->is_skipped ) {
            $report->num_tests_run($num_tests);
            if ( !$report->has_plan ) {
                $report->tests_planned($num_tests);
            }
        }
        return $report;
    };

    my $RUN_TEST_CLASS = sub {
        local *__ANON__ = 'ANON_RUN_TEST_CLASS';
        my ( $self, $test_class ) = @_;
        my $builder   = $self->test_configuration->builder;
        my $report = $self->test_report;

        return sub {

            # set up test class reporting
            my $test_instance
              = $test_class->new( $self->test_configuration->args );
            my $report_class = Test::Class::MOP::Report::Class->new(
                {   name => $test_class,
                }
            );
            $report->add_test_class($report_class);
            my @test_methods = $test_instance->test_methods;
            unless (@test_methods) {
                my $message = "Skipping '$test_class': no test methods found";
                $report_class->skipped($message);
                $builder->plan( skip_all => $message );
                return;
            }
            $report_class->_start_benchmark;

            $report->_inc_test_methods( scalar @test_methods );

            # startup
            if (!$test_instance->$RUN_TEST_CONTROL_METHOD(
                    'test_startup', $report_class
                )
              )
            {
                fail "test_startup failed";
                return;
            }

            if ( my $message = $test_instance->test_skip ) {

                # test_startup skipped the class
                $report_class->skipped($message);
                $builder->plan( skip_all => $message );
                return;
            }

            $builder->plan( tests => scalar @test_methods );

            # run test methods
            foreach my $test_method (@test_methods) {
                my $report_method = $self->$RUN_TEST_METHOD(
                    $test_instance,
                    $test_method
                );
                $report->_inc_tests( $report_method->num_tests_run );
            }

            # shutdown
            $test_instance->$RUN_TEST_CONTROL_METHOD(
                'test_shutdown',
                $report_class
            ) or fail("test_shutdown() failed");

            # finalize reporting
            $report_class->_end_benchmark;
            if ( $self->test_configuration->show_timing ) {
                my $time = $report_class->time->duration;
                $self->test_configuration->builder->diag("$test_class: $time");
            }
        };
    };

    method runtests {
        my $report = $self->test_report;
        $report->_start_benchmark;
        my @test_classes = $self->test_classes;

        my $builder = $self->test_configuration->builder;
        $builder->plan( tests => scalar @test_classes );
        foreach my $test_class (@test_classes) {
            Test::Most::explain("\nRunning tests for $test_class\n\n");
            $builder->subtest(
                $test_class,
                $self->$RUN_TEST_CLASS($test_class),
            );
        }

        $builder->diag(<<"END") if $self->test_configuration->statistics;
    Test classes:    @{[ $report->num_test_classes ]}
    Test methods:    @{[ $report->num_test_methods ]}
    Total tests run: @{[ $report->num_tests_run ]}
END
        $builder->done_testing;
        $report->_end_benchmark;
        return $self;
    }

    method test_classes {
        if ( my $classes = $self->test_configuration->test_classes ) {
            if (@$classes) {    # ignore it if the array is empty
                return @$classes;
            }
        }
        state $classes;
        unless ($classes) {
            $classes = [
                sort
                grep { $_ ne __CLASS__ && $_->isa(__CLASS__) }
                map { s!/!::!g; s/\.pm$//; $_ } keys %INC
            ];
        }

        # eventually we'll want to control the test class order
        return @$classes;
    }

    method test_methods {
        my @method_list;

        # XXX walk the inheritance tree to gather up all methods. I'm sure
        # there's a better way to do this, but I don't know it.
        my @meta_classes = mop::meta($self);
        while ( my $meta = mop::meta($meta_classes[-1]->superclass) ) {
            last if $meta->name eq __CLASS__;
            push @meta_classes => $meta;
        }

        # XXX this was supposed to work, but didn't. I'll look at it later.
        #my @methods = map { mop::meta($_)->methods } @{ mro::get_linear_isa($self) };

        foreach my $meta (@meta_classes) {
            foreach my $method ( $meta->methods ) {
                next unless $method->isa('TestMethodMeta') && $method->is_testcase;

                # don't use anything defined in this package
                my $name = $method->name;
                next if __CLASS__->can($name);
                push @method_list => $name;
            }
        }

        if ( my $include = $self->test_configuration->include ) {
            @method_list = grep {/$include/} @method_list;
        }
        if ( my $exclude = $self->test_configuration->exclude ) {
            @method_list = grep { !/$exclude/ } @method_list;
        }

        return uniq(
            $self->test_configuration->randomize
            ? shuffle(@method_list)
            : sort @method_list
        );
    }

    # empty stub methods guarantee that subclasses can always call these
    method test_startup  { }
    method test_setup    { }
    method test_teardown { }
    method test_shutdown { }
}

__END__

=head1 SYNOPSIS

    use mop;

    class TestsFor::DateTime extends Test::Class::MOP {
        use DateTime;
        use Test::Most;

        # methods that begin with test_ are test methods.
        method constructor($report) is testcase {
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

=head1 DESCRIPTION

This is B<ALPHA> code. I encourage you to give it a shot if you want test
classes based on MOP, along with reporting. Feedback welcome as we try to
improve it.

This is a proof of concept for writing Test::Class-style tests with
L<https://github.com/stevan/p5-mop-redux>. Better docs will come later.

=head1 BASICS


=head2 Declare a test method

All method that have the C<is testcase> trait are test methods. Methods that do
not are not test methods.

 class TestsFor::Some::Class extends Test::Class::MOP {
     use Test::Most;

     method this_is_a_method($report) is testcase {
         $self->this_is_not_a_test_method;
         ok 1, 'whee!';
     }

     method this_is_not_a_test_method {
        # but you can, of course, call it like normal
     }
 }

=head2 Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit C<done_testing> call.

If you prefer, you can declare a plan in a test method:

    method something($report) is testcase {
        $report->plan($num_tests);
        ...
    }

You may call C<plan()> multiple times for a given test method. Each call to
C<plan()> will add that number of tests to the plan.  For example, with an
overridden method:

    method something($report) is testcase {
        $self->next::method($report);
        $report->plan($num_extra_tests);
        # more tests
    };

Please note that if you call C<plan>, the plan will still show up at the end
of the subtest run, but you'll get the desired failure if the number of tests
run does not match the plan.

=head2 Inheriting from another Test::Class::MOP class

List it as C<extends>, as you would expect.

 use mop;

 # assumes TestsFor::Some::Class inherits from Test::Class::MOP
 class TestsFor::Some::Class::Subclass extends TestsFor::Some::Class {
     use Test::Most;

     method overrides_something ($report) is testcase {
         my $class = $self->test_class;
         ok 1, "I overrode my parent! ($class)";
     }

     method test_this_baby($report) is testcase {
         my $class = $self->test_class;
         pass "This should run before my parent method ($class)";
         $self->next::method($report);
     }

     method this_should_not_run {
         fail "We should never see this test";
     }

     method this_should_be_run($report) is testcase {
         for ( 1 .. 5 ) {
             pass "This is test number $_ in this method";
         }
     }
 }

=head1 TEST CONTROL METHODS

Do not run tests in test control methods. This will cause the test control
method to fail (this is a feature, not a bug).  If a test control method
fails, the class/method will fail and testing for that class should stop.
Further, applying the C<is testcase> trait to a test control method is also
fatal.

B<Every> test control method will be passed two arguments. The first is the
C<$self> invocant. The second is an object implementing
L<Test::Class::MOP::Role::Reporting>. You may find that the C<notes> hashref
is a handy way of recording information you later wish to use if you call
C<< $test_suite->test_report >>.

These are:

=over 4

=item * C<test_startup>

 method test_startup($report) {
    $self->next::method($report);
    # more startup
 }

Runs at the start of each test class. If you need to know the name of the
class you're running this in (though usually you shouldn't), use
C<< $self->test_class >>, or the C<name> method on the C<$report> object.

The C<$report> object is a L<Test::Class::MOP::Report::Class> object.

=item * C<test_setup>

 method test_setup($report) {
    $self->next::method($report);
    # more setup
 }

Runs at the start of each test method. If you must know the name of the test
you're about to run, you can call C<< $report->name >>.

The C<$report> object is a L<Test::Class::MOP::Report::Method> object.

=item * C<test_teardown>

 method test_teardown($report) {
    # more teardown
    $self->next::method($report);
 }

Runs at the end of each test method. 

The C<$report> object is a L<Test::Class::MOP::Report::Method> object.

=item * C<test_shutdown>

 method test_shutdown($report) {
     # more teardown
     $self->next::method($report);
 }

Runs at the end of each test class. 

The C<$report> object is a L<Test::Class::MOP::Report::Class> object.

=back

To override a test control method, just remember that this is OO:

 method test_setup($report) {
     $self->next::method($report); # optional to call parent test_setup
     # more setup code here
 }

=head1 RUNNING THE TEST SUITE

We recommend using L<Test::Class::MOP::Load> as the driver for your test
suite. Simply point it at the directory or directories containing your test
classes:

 use Test::Class::MOP::Load 't/lib';
 Test::Class::MOP->new->runtests;

By running C<Test::Class::MOP> with a single driver script like this, all
classes are loaded once and this can be a significant performance boost. This
does mean a global state will be shared, so keep this in mind.

You can also pass arguments to C<Test::Class::MOP>'s contructor.

 my $test_suite = Test::Class::MOP->new({
     show_timing => 1,
     randomize   => 0,
     statistics  => 1,
 });
 # do something
 $test_suite->runtests;

The attributes passed in the constructor are not directly available from the
L<Test::Class::MOP> instance. They're available in
L<Test::Class::MOP::Config> and to avoid namespace pollution, we do I<not>
delegate the attributes directly as a result. If you need them at runtime,
you'll need to access the C<test_configuration> attribute:

 my $builder = $test_suite->test_configuration->builder;

=head2 Contructor Attributes

=over 4

=item * C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

=item * C<statistics>

Boolean. Will display number of classes, test methods and tests run.

=item * C<randomize>

Boolean. Will run test methods in a random order.

=item * C<builder>

Defaults to C<< Test::Builder->new >>. You can supply your own builder if you
want, but it must conform to the L<Test::Builder> interface. We make no
guarantees about which part of the interface it needs.

=item * C<test_classes>

Takes a class name or an array reference of class names. If it is present,
only these test classes will be run. This is very useful if you wish to run an
individual class as a test:

    Test::Class::MOP->new(
        test_classes => $ENV{TEST_CLASS}, # ignored if undef
    )->runtests;

You can also achieve this effect by writing a subclass and overriding the
C<test_classes> method, but this makes it trivial to do this:

    TEST_CLASS=TestsFor::Our::Company::Invoice prove -lv t/test_classes.t

Alternatively:

    Test::Class::MOP->new(
        test_classes => \@ARGV, # ignored if empty
    )->runtests;

That lets you use the arisdottle to provide arguments to your test driver
script:

    prove -lv t/test_classes.t :: TestsFor::Our::Company::Invoice TestsFor::Something::Else

=item * C<include>

Regex. If present, only test methods whose name matches C<include> will be
included. B<However>, they must still start with C<test_>.

For example:

 my $test_suite = Test::Class::MOP->new({
     include => qr/customer/,
 });

The above constructor will let you match test methods named C<test_customer>
and C<test_customer_account>, but will not suddenly match a method named
C<default_customer>.

By enforcing the leading C<test_> behavior, we don't surprise developers who
are trying to figure out why C<default_customer> is being run as a test. This
means an C<include> such as C<< /^customer.*/ >> will never run any tests.

=item * C<exclude>

Regex. If present, only test methods whose names don't match C<exclude> will be
included. B<However>, they must still start with C<test_>. See C<include>.

=back

=head2 Skipping Classes and Methods

If you wish to skip a class, set the reason in the C<test_startup> method.

    method test_startup($report) {
        $self->test_skip("I don't want to run this class");
    }

If you wish to skip an individual method, do so in the C<test_setup> method.

    method test_setup($report) {
        if ( 'test_time_travel' eq $report->name ) {
            $self->test_skip("Time travel not yet available");
        }
    }

=head1 THINGS YOU CAN OVERRIDE

... but probably shouldn't.

As a general rule, methods beginning with C</^test_/> are reserved for
L<Test::Class::MOP>. This makes it easier to remember what you can and
cannot override.

=head2 C<test_configuration>

 my $test_configuration = $self->test_configuration;

Returns the L<Test::Class::MOP::Config> object.

=head2 C<test_report>

 my $report = $self->test_report;

Returns the L<Test::Class::MOP::Report> object. Useful if you want to do
your own reporting and not rely on the default output provided with the
C<statistics> boolean option.

=head2 C<test_class>

 my $class = $self->test_class;

Returns the name for this test class. Useful if you rebless an object (such as
applying a role at runtime) and don't want to lose the original class name.

=head2 C<test_classes>

You may override this in a subclass. Currently returns a sorted list of all
loaded classes that inherit directly or indirectly through
L<Test::Class::MOP>

=head2 C<test_methods>

You may override this in a subclass. Currently returns all methods in a test
class that start with C<test_> (except for the test control methods).

Please note that the behavior for C<include> and C<exclude> is also contained
in this method. If you override it, you will need to account for those
yourself.

=head2 C<runtests>

If you really, really want to change how this module works, you can override
the C<runtests> method. We don't recommend it.

Returns the L<Test::Class::MOP> instance.

=head1 SAMPLE TAP OUTPUT

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

=head1 REPORTING

See L<Test::Class::MOP::Report> for more detailed information on reporting.

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

=head1 EXTRAS

If you would like L<Test::Class::MOP> to take care of loading your classes
for you, see L<Test::Class::MOP::Role::AutoUse> in this distribution.

=head1 TODO

=over 4

=item *  New test phases - start and end suite, not just start and end class/method

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-class-moose at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-MOP>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::MOP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-MOP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Class-MOP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Class-MOP>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Class-MOP/>

=back

=head1 SEE ALSO

=over 4

=item * L<Test::Routine>

I always pointed people to this when they would ask about L<Test::Class> +
L<MOP>, but I would always hear "that's not quite what I'm looking for".
I don't quite understand what the reasoning was, but I strongly encourage you
to take a look at L<Test::Routine>.

=item * L<Test::Roo>

L<Test::Routine>, but with L<Moo> instead of L<MOP>.

=item * L<Test::Class>

xUnit-style testing in Perl.

=item * L<Test::Class::Most>

L<Test::Class> + L<Test::Most>.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Tom Beresford (beresfordt) for spotting an issue when a class has no
test methods.

Thanks to Judioo for adding the randomize attribute.

Thanks to Adrian Howard for L<Test::Class>.

=cut

1;
