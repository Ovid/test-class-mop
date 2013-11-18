use mop;
class TestsFor::Person extends Test::Class::MOP
 with Test::Class::MOP::Role::AutoUse {
    use Test::Most;
    has $!test_fixture is rw;

    # XXX bare return required due to this bug:
    # https://github.com/stevan/p5-mop-redux/issues/148
    method extra_constructor_args { return }

    method test_setup($report) {
        $self->next::method($report);
        $self->test_fixture($self->class_name->new(
            first_name => 'Bob',
            last_name  => 'Dobbs',
            $self->extra_constructor_args,
        ));
    }

    method test_person($report) is testcase {
        $report->plan(1);
        is $self->test_fixture->full_name, 'Bob Dobbs',
            'Our full name should be correct';
    }
}
