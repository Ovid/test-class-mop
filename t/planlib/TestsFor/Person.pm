use mop;
class TestsFor::Person extends Test::Class::MOP
 with Test::Class::MOP::Role::AutoUse {
    use Test::Most;
    has $!test_fixture is rw;

    method extra_constructor_args { return }

    method test_setup($report) {
        $self->next::method($report);
        $self->test_fixture($self->class_name->new(
            first_name => 'Bob',
            last_name  => 'Dobbs',
            $self->extra_constructor_args,
        ));
    }

    method test_person($report) {
        $report->plan(1);
        is $self->test_fixture->full_name, 'Bob Dobbs',
            'Our full name should be correct';
    }
}
