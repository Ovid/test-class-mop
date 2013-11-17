# PODNAME: Test::Class::MOP::Report
# ABSTRACT: Test information for Test::Class::MOP

use mop;
use strict;
use warnings;

class Test::Class::MOP::Report with Test::Class::MOP::Role::Timing {
    has $!num_test_methods is rw = 0;
    has $!num_tests_run    is rw = 0;
    has $!test_classes     is ro = [];

    method _inc_test_methods($test_methods) {
        $test_methods //= 1;
        $!num_test_methods += $test_methods;
    }
    method _inc_tests($tests) {
        $tests //= 1;
        $!num_tests_run += $tests;
    }
    method current_class {
        return $!test_classes->[-1];
    }
    method all_test_classes {
        return @{ $!test_classes }
    }
    method add_test_class($test_class) {
        push $!test_classes => $test_class;
    }
    method num_test_classes {
        return scalar @{ $!test_classes };
    }
}

__END__

=head1 SYNOPSIS

 my $report = Test::Class::MOP->new->runtests->test_report;

=head1 DESCRIPTION

When working with larger test suites, it's useful to have full reporting
information avaiable about the test suite. The reporting features of
L<Test::Class::MOP> allow you to report on the number of test classes and
methods run (and number of tests), along with timing information to help you
track down which tests are running slowly. You can even run tests on your
report information:

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::MOP::Load qw(t/lib);
    my $test_suite = Test::Class::MOP->new;

    subtest 'run the test suite' => sub {
        $test_suite->runtests;
    };
    my $report = $test_suite->test_report;
    my $duration = $report->time->duration;
    diag "Test suite run time: $duration";

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


Reporting is currently in alpha. The interface is not guaranteed to be stable.

=head2 The Report

 my $report = Test::Class::MOP->new->runtests->test_report;

Or:

 my $test_suite = Test::Class::MOP->new;
 $test_suite->runtests;
 my $report = $test_suite->test_report;

After the test suite is run, you can call the C<test_report> method to get the
report. The test report is a L<Test::Class::MOP::Report> object. This object
provides the following methods:

=head3 C<test_classes>

Returns an array reference of L<Test::Class::MOP::Report::Class> instances.

=head3 C<all_test_classes>

Returns an array of L<Test::Class::MOP::Report::Class> instances.

=head3 C<num_test_classes>

Integer. The number of test classes run.

=head3 C<num_test_methods>

Integer. The number of test methods run.

=head3 C<num_tests_run>

Integer. The number of tests run.

=head3 C<time>

Returns a L<Test::Class::MOP::Report::Time> object. This object
represents the duration of the entire test suite.

=head2 Test Report for Classes

Each L<Test::Class::MOP::Report::Class> instance provides the following
methods:

=head3 C<test_methods>

Returns an array reference of L<Test::Class::MOP::Report::Method>
objects.

=head3 C<all_test_methods>

Returns an array of L<Test::Class::MOP::Report::Method> objects.

=head3 C<error>

If this class could not be run, returns a string explaining the error.

=head3 C<has_error>

Returns a boolean indicating whether or not the class has an error.

=head3 C<name>

The name of the test class.

=head3 C<notes>

A hashref. The end user may use this to store anything desired.

=head3 C<skipped>

If the class or method is skipped, this will return the skip message.

=head3 C<is_skipped>

Returns true if the class or method is skipped.

=head3 C<time>

Returns a L<Test::Class::MOP::Report::Time> object. This object
represents the duration of this class.

=head2 Test Report for Methods

Each L<Test::Class::MOP::Report::Method> instance provides the following
methods:

=head3 C<name>

The "name" of the test method.

=head3 C<notes>

A hashref. The end user may use this to store anything desired.

=head3 C<skipped>

If the class or method is skipped, this will return the skip message.

=head3 C<is_skipped>

Returns true if the class or method is skipped.

=head3 C<time>

Returns a L<Test::Class::MOP::Report::Time> object. This object
represents the duration of this class or method.

=head2 Test Report for Time

Each L<Test::Class::MOP::Report::Time> instance has the following methods:

=head3 C<real>

    my $real = $time->real;

Returns the "real" amount of time the class or method took to run.

=head3 C<user>

    my $user = $time->user;

Returns the "user" amount of time the class or method took to run.

=head3 C<system>

    my $system = $time->system;

Returns the "system" amount of time the class or method took to run.

=head3 C<duration>

Returns the returns a human-readable representation of the time this class or
method took to run. Something like:

  0.00177908 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)

=head1 TRUSTED METHODS

The following L<Test::Class::MOP::Report> methods are for internal use only
and are called by L<Test::Class::MOP>.  They are included here for those who
might want to hack on L<Test::Class::MOP>.

=head2 C<_inc_test_methods>

    $statistics->_inc_test_methods;        # increments by 1
    $statistics->_inc_test_methods($x);    # increments by $x

=head2 C<_inc_tests>

    $statistics->_inc_tests;        # increments by 1
    $statistics->_inc_tests($x);    # increments by $x

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

=cut

1;
