use mop;
class TestsFor::Basic extends Test::Class::MOP {
    use Test::Most;

    method test_me is testcase {
        my $class = $self->test_class;
        ok 1, "test_me() ran ($class)";
        ok 2, "this is another test ($class)";
    }

    method test_this_baby is testcase {
        my $class = $self->test_class;
        is 2, 2, "whee! ($class)";
    }
}
