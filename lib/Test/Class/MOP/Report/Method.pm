# ABSTRACT: Reporting on test methods

use mop;
class Test::Class::MOP::Report::Method 
 with Test::Class::MOP::Role::Reporting {
    has $!num_tests_run is rw = 0;
    has $!tests_planned is rw;

    method has_plan { defined $!tests_planned }

    method plan($integer) {
        $!tests_planned += $integer;
    }
}

__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::MOP::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<num_tests_run>

    my $tests_run = $method->num_tests_run;

The number of tests run for this test method.

=head2 C<tests_planned>

    my $tests_planned = $method->tests_planned;

The number of tests planned for this test method. If a plan has not been
explicitly set with C<$report->test_plan>, then this number will always be
equal to the number of tests run.
