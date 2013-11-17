use lib 't/lib';
{
    package TestsFor::PersonTest;
    use Test::Class::MOP;
    with 'Test::Class::MOP::Role::AutoUse';

    sub test_basic {
        my $test = shift;
        is $test->class_name, 'PersonTest', 'The classname should be correctly returned';
        ok my $person = $test->class_name->new(
            first_name => 'Bob',
            last_name => 'Dobbs',
        ), '... and the class should already be loaded for us';
        isa_ok $person, $test->class_name, '... and the object the constructor returns';
        is $person->full_name, 'Bob Dobbs', '... and the class should work as expected';
    }
}

Test::Class::MOP->new->runtests;
