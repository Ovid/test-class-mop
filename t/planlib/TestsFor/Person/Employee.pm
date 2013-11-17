use mop;

class TestsFor::Person::Employee extends TestsFor::Person {
    use Test::Most;
    method extra_constructor_args {
        return ( employee_number => 666 );
    }

    method test_person($report) {
        $self->next::method($report);
        $report->plan(1);
        is $self->test_fixture->employee_number, 666,
          '... and we should get the correct employee number';
    }
}
