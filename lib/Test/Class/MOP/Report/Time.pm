# PODNAME: Test::Class::MOP::Report::Time
# ABSTRACT: Reporting object for timing

use mop;
use strict;
use warnings;

class Test::Class::MOP::Report::Time {
    use Benchmark qw(timestr :hireswallclock);

    has $!timediff         is ro;
    has $!real             is ro;
    has $!user             is ro;
    has $!system           is ro;
    has $!_children_user   is ro;
    has $!_children_system is ro;
    has $!_iters           is ro;

    method BUILD {
        # XXX ugly. Fix this
        my %args;
        @args{
            qw/
              real
              user
              system
              _children_user
              _children_system
              _iters
              /
          } = @{$!timediff};
          $!real             = $args{real};
          $!user             = $args{user};
          $!system           = $args{system};
          $!_children_user   = $args{_children_user};
          $!_children_system = $args{_children_system};
          $!_iters           = $args{_iters};
    }

    method duration {
        return timestr($!timediff);
    }
}

__END__

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

All times are in seconds.

=head1 ATTRIBUTES

=head2 C<real>

    my $real = $time->real;

Returns the "real" amount of time the class or method took to run.
    
=head2 C<user>

    my $user = $time->user;

Returns the "user" amount of time the class or method took to run.
    
=head2 C<system>

    my $system = $time->system;

Returns the "system" amount of time the class or method took to run.

=head1 METHODS

=head2 C<duration>

Returns the returns a human-readable representation of the time this class or
method took to run. Something like:

  0.00177908 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
