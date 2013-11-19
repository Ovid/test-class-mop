use mop;
class TestsFor::SkipSomeMethods extends Test::Class::MOP {
    use Test::Most;
    method test_setup($report) {
        if ( 'test_me' eq $report->name ) {
            $self->test_skip('only methods listed as skipped should be skipped');
        }
    }

    method test_me($report) is testcase {
        my $class = $self->test_class;
        ok 1, "test_me() ran ($class)";
        ok 2, "this is another test ($class)";
    }

    method test_this_baby($report) is testcase {
        my $class = $self->test_class;
        is 2, 2, "whee! ($class)";
    }

    method test_again($report) is testcase { ok 1, 'in test_again' }
}
