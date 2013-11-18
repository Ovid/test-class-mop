# PODNAME: Test::Class::MOP::Config
# ABSTRACT: Configuration information for Test::Class::MOP

use mop;

class Test::Class::MOP::Config {
    has $!show_timing     is ro = ( $_->use_environment && $ENV{HARNESS_IS_VERBOSE} );
    has $!statistics      is ro = ( $_->use_environment && $ENV{HARNESS_IS_VERBOSE} );
    has $!builder         is ro = Test::Builder->new;
    has $!use_environment is ro;
    has $!test_class      is ro;
    has $!test_classes    is ro = [];
    has $!randomize       is ro;
    has $!include         is ro;
    has $!exclude         is ro;
    has $!include_tags    is ro = [];
    has $!exclude_tags    is ro = [];

    method BUILD {
        $!test_classes = [$!test_classes] unless ref $!test_classes;
    }

    method clear_include_tags {
        $!include_tags = [];
    }
    method clear_exclude_tags {
        $!exclude_tags = [];
    }

    method args {
        my @attributes = map { $_->name } mop::meta( ref $self )->attributes;

        # names start with $!, so for now we'll hardcode 'em because this
        # interface may chance later
        return {
            map { defined $self->$_ ? ( $_ => $self->$_ ) : () } qw/
                show_timing
                statistics
                builder
                use_environment
                test_class
                test_classes
                randomize
                include
                exclude
                include_tags
                exclude_tags
            /
        };
    }
}

__END__

=head1 SYNOPSIS

 my $tc_config = Test::Class::MOP::Config->new({
     show_timing => 1,
     builder     => Test::Builder->new,
     statistics  => 1,
     randomize   => 0,
 });
 my $test_suite = Test::Class::MOP->new($tc_config);

=head1 DESCRIPTION

For internal use only (maybe I'll expose it later). Not guaranteed to be
stable.

This class defines many of the attributes for L<Test::Class::MOP>. They're
kept here to minimize namespace pollution in L<Test::Class::MOP>.

=head1 ATTRIBUTES

=head2 * C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

=head2 * C<statistics>

Boolean. Will display number of classes, test methods and tests run.

=head2 * C<use_environment>

Boolean.  Sets show_timing and statistics to true if your test harness is running verbosely, false otherwise.

=head2 C<test_classes>

Takes a class name or an array reference of class names. If it is present, the
C<test_classes> method will only return these classes. This is very useful if
you wish to run an individual class as a test:

    Test::Class::MOP->new(
        test_classes => $ENV{TEST_CLASS}, # ignored if undef
    )->runtests;

=head2 C<include_tags>

Array ref of strings matching method tags (a single string is also ok). If
present, only test methods whose tags match C<include_tags> or whose tags
don't match C<exclude_tags> will be included. B<However>, they must still
start with C<test_>.

For example:

 my $test_suite = Test::Class::MOP->new({
     include_tags => [qw/api database/],
 });

The above constructor will only run tests tagged with C<api> or C<database>.

=head2 C<exclude_tags>

The same as C<include_tags>, but will exclude the tests rather than include
them. For example, if your network is down:

 my $test_suite = Test::Class::MOP->new({
     exclude_tags => [ 'network' ],
 });

 # or
 my $test_suite = Test::Class::MOP->new({
     exclude_tags => 'network',
 });


=head2 C<builder>

Usually defaults to C<< Test::Builder->new >>, but you could substitute your
own if it conforms to the interface.

=head2 C<randomize>

Boolean. Will run tests in a random order.

=head1 METHODS

=head2 C<args>

 my $tests = Some::Test::Class->new($test_suite->test_configuration->args);

Returns a hash reference of the args used to build the configuration. Used in
testing. You probably won't need it.

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

=head1 ACKNOWLEDGEMENTS

=cut

1;
