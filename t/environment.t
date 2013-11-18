#!/usr/bin/env perl
use lib 'lib';
use Test::Most;
use Scalar::Util 'looks_like_number';
use Test::Class::MOP::Load qw(t/lib);

plan skip_all => 'https://github.com/stevan/p5-mop-redux/issues/151';


{
    my $test_suite = Test::Class::MOP->new;
    is ( $test_suite->test_configuration->show_timing, undef, 'show timing is undef by default' );
    is ( $test_suite->test_configuration->statistics, undef, 'statistics is undef by default' );
}

{
    my $test_suite = Test::Class::MOP->new(
        show_timing => 1,
        statistics  => 1,
    );
    is ( $test_suite->test_configuration->show_timing, 1, 'show timing can be set to 1' );
    is ( $test_suite->test_configuration->statistics, 1, 'statistics can be set to 1' );
}

{
    my $test_suite = Test::Class::MOP->new(
        show_timing => 1,
        statistics  => 1,
    );
    is ( $test_suite->test_configuration->show_timing, 1, 'show timing can be set to 1' );
    is ( $test_suite->test_configuration->statistics, 1, 'statistics can be set to 1' );
}

{
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    my $test_suite = Test::Class::MOP->new(
        use_environment => 1,
    );
    is ( $test_suite->test_configuration->show_timing, 1, 'show timing set to 1 when harness is verbose' );
    is ( $test_suite->test_configuration->statistics, 1, 'statistics set to 1 when harness is verbose' );

    use Data::Dumper;
#    warn( Dumper $test_suite->test_configuration->args );

}

{
    local $ENV{HARNESS_IS_VERBOSE} = 0;
    my $test_suite = Test::Class::MOP->new(
        use_environment => 1,
    );
    ok !$test_suite->test_configuration->show_timing, 'show timing set to false when harness is not verbose';
    ok !$test_suite->test_configuration->statistics, 'statistics set to false when harness is not verbose';
}





done_testing;
