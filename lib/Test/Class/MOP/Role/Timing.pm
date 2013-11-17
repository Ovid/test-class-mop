# ABSTRACT: Report timing role

use mop;

role Test::Class::MOP::Role::Timing {
    use Benchmark qw(timediff :hireswallclock);
    use Test::Class::MOP::Report::Time;

    has $!start is ro = Benchmark->new;
    has $!end   is rw;
    has $!time  is rw;

    # these are trusted methods that should only be called by Test::Class::MOP
    method _start_benchmark { $!start = Benchmark->new }

    method _end_benchmark {
        $!end  = Benchmark->new;
        $!time = Test::Class::MOP::Report::Time->new(
            timediff => timediff( $!end, $!start ) );
    }
}

__END__

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

=head1 REQUIRES

None.

=head1 PROVIDED

=head1 ATTRIBUTES

=head2 C<time>

Returns a L<Test::Class::MOP::Report::Time> object. This object
represents the duration of this class or method.
