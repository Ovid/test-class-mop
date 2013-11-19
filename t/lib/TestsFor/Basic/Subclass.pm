use mop;
class TestsFor::Basic::Subclass extends TestsFor::Basic {
    use Test::Most;

    method test_this_baby($report) is testcase {
        my $class = $self->test_class;
        pass "This should run before my parent method ($class)";
        $self->next::method($report);
    }

    method test_me is testcase {
        my $class = $self->test_class;
        ok 1, "I overrode my parent! ($class)";
    }

    method this_should_not_run {
        fail "We should never see this test";
    }

    method this_should_be_run is testcase {
        for ( 1 .. 5 ) {
            pass "This is test number $_ in this method";
        }
    }
}
