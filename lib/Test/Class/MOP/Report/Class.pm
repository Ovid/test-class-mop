# PODNAME: Test::Class::MOP::Report::Class
# ABSTRACT: Reporting on test classes

use mop;
use strict;
use warnings;

class Test::Class::MOP::Report::Class
 with Test::Class::MOP::Role::Reporting {
    has $!error is rw;
    method has_error { defined $!error }

    has $!test_methods is ro = [];
    
    method all_test_methods { @{ $!test_methods } }

    method add_test_method($test_method) {
        push $!test_methods => $test_method;
    }
    method num_test_methods {
        return scalar @{ $!test_methods };
    }
}

__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::MOP::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<test_methods>

Returns an array reference of L<Test::Class::MOP::Report::Method>
objects.

=head2 C<all_test_methods>

Returns an array of L<Test::Class::MOP::Report::Method> objects.

=head2 C<error>

If this class could not be run, returns a string explaining the error.

=head2 C<has_error>

Returns a boolean indicating whether or not the class has an error.
