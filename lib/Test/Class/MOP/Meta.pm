# PODNAME: Test::Class::MOP::Meta
# Abstract: Custom Test::Class::MOP metaclass
use 5.18.0;
use strict;
use warnings;
use Carp;

{
    use mop;
    sub testcase {
        my $method = shift;
        Carp::croak("testcase trait is only valid on methods")
          unless $method->isa('mop::method');

        my $name = $method->name;
        if ( grep {/^test_(?:startup|setup|teardown|shutdown)$/} $name ) {

            # XXX how do I get the class name here?
            croak("Test control methods may not use a testcase trait: $name");
        }
    }

    class TestMethodMeta extends mop::method {
        method is_testcase(@args) {
            my @traits = mop::traits::util::applied_traits($self);
            foreach my $trait (@traits) {
                if ( $trait->{trait} == \&testcase ) {
                    return 1;
                }
            }
            return;
        }
    }

    class TestClassMeta extends mop::class {
        method method_class { 'TestMethodMeta' }
    }

    class Parent meta TestClassMeta {
        method this is testcase {
            return 'parent.this';
        }

        method that {
            return 'parent.that';
        }
    }
}
