use mop;
class TestsFor::Basic::Subclass extends TestsFor::Basic {
    use Test::Most;

    method test_me {
        my $class = $self->test_class;
        ok 1, "I overrode my parent! ($class)";
    }

    method this_should_not_run {
        fail "We should never see this test";
    }

    method test_this_should_be_run {
        for ( 1 .. 5 ) {
            pass "This is test number $_ in this method";
        }
    }
}
