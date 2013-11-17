package Test::Class::MOP::Role::Reporting;

# ABSTRACT: Reporting gathering role

use mop;

role Test::Class::MOP::Role::Reporting with Test::Class::MOP::Role::Timing {
    has $!name    is ro;
    has $!notes   is ro = {};
    has $!skipped is rw;

    method is_skipped { defined $!skipped }
}

__END__

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

=head1 IMPLEMENTS

L<Test::Class::MOP::Role::Timing>.

=head1 REQUIRES

None.

=head1 PROVIDED

=head1 ATTRIBUTES

=head2 C<name>

The "name" of the statistic. For a class, this should be the class name. For a
method, it should be the method name.

=head2 C<notes>

A hashref. The end user may use this to store anything desired.

=head2 C<skipped>

If the class or method is skipped, this will return the skip message.

=head2 C<is_skipped>

Returns true if the class or method is skipped.

=head2 C<time>

(From L<Test::Class::MOP::Role::Timing>)

Returns a L<Test::Class::MOP::Report::Time> object. This object
represents the duration of this class or method.
