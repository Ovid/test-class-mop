use mop;
use lib 't/lib';

class TestsFor::PersonTest extends Test::Class::MOP
 with Test::Class::MOP::Role::AutoUse {
    method test_basic($report) {
        is $self->class_name, 'PersonTest', 'The classname should be correctly returned';
        ok my $person = $self->class_name->new(
            first_name => 'Bob',
            last_name => 'Dobbs',
        ), '... and the class should already be loaded for us';
        isa_ok $person, $self->class_name, '... and the object the constructor returns';
        is $person->full_name, 'Bob Dobbs', '... and the class should work as expected';
    }
}

Test::Class::MOP->new->runtests;
