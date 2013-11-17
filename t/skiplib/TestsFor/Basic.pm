use mop;
class TestsFor::Basic extends Test::Class::MOP {
    use Test::Most;
    method test_startup($report) {
        $self->next::method($report);
        $self->test_skip('all methods should be skipped');
    }

    method test_me($report) {
        my $class = $self->test_class;
        ok 1, "test_me() ran ($class)";
        ok 2, "this is another test ($class)";
    }

    method test_this_baby($report) {
        my $class = $self->test_class;
        is 2, 2, "whee! ($class)";
    }
}
