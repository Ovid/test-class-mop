package Test::Class::MOP::Tutorial

# ABSTRACT: A starting guide for Test::Class::MOP

# there is no code here, but we're moving this from .pod to .pm to try to work
# around a strange bug where this is showing up instead of main docs on
# metacpan and cpan

1;

__END__
=head1 Getting Started

Automated testing is wonderful. Verifying your program's correctness in all
possible ways is a good thing that will save you time (and programmer time is
money).

Procedural tests like C<Test::More> are a good, general way to write tests for
all kinds of things. However, it is not very good when you're trying describe
relationships between tests. For this, a class-based test would work better,
because you could use the standard OO-techniques for describing object
relationships like inheritance.

When testing objects, it's good for code re-use to have test classes that match
the relationships between the regular objects. By creating test classes with
the same relationships, you can quickly increase test coverage by testing the
base class, and all the child classes can inherit those tests!

=head2 A Test Class

The first and most crucial part of using C<Test::Class::MOP> is a class that
runs some tests. C<Test::Class::MOP> loads a few modules for you
automatically, so the boilerplate is, at minimum:

    package TestsFor::My::Test::Class;
    use Test::Class::MOP;

C<Test::Class::MOP> loads C<strict>, C<warnings>, C<MOP>, and
C<Test::Most> (which includes C<Test::More>, C<Test::Deep>,
C<Test::Exception>, and C<Test::Differences>).

I put my test classes in the C<t/lib/TestsFor> directory, to keep the
separated from my other classes that help testing (C<t/lib>) and my other test
scripts. This is just a convention; the directory can be anything you want it
to be, but it is a good idea to keep your test classes separate from your
other test-related modules.

Now, we need a method that runs our test. C<Test::Class::MOP> test
methods start with C<test_>. Any method that starts with C<test_> will be run
as a test.

    use My::Module;

    sub test_construction {
        my ( $test, $report ) = @_;
        my $obj = My::Module->new;
        isa_ok $obj, 'My::Module';
    }

Every C<test_> method is run as a subtest, and no plan is required. We can have as
many C<test_> methods as we want.

=head2 A Test Runner

Now that we have a test class, we need a way for prove to load and run them.
C<Test::Class::MOP> can load our test modules from a given directory, and it
has a runtests() method that will run any test modules that have already been
loaded.

    # t/test_class_tests.t
    use File::Spec::Functions qw( catdir );
    use FindBin qw( $Bin );
    use Test::Class::MOP::Load qw( catdir( $Bin, 't', 'lib' ) );
    Test::Class::MOP->new->runtests;

Or if you're not worried about the portability of that directory:

    use Test::Class::MOP::Load 't/lib';
    Test::Class::MOP->new->runtests;

This test script will load all of the C<Test::Class::MOP> modules inside
C<t/lib/> and then run them. All your test modules get run by this one script,
but since they're run as subtests, you will get a report on how many test
classes failed.

We can run our test script using prove. I'll turn on verbose output (-v) to
show you what the TAP output looks like

    prove -v t/test_class_tests.t
    t/test_class_tests.t ..
    1..1
    #
    # Running tests for TestsFor::My::Class
    #
        1..1
        # TestsFor::My::Class->test_something()
            ok 1 - I tested something!
            1..1
        ok 1 - test_something
    ok 1 - TestsFor::My::Class
    ok
    All tests successful.
    Files=1, Tests=1,  0 wallclock secs ( 0.03 usr  0.01 sys +  0.34 cusr  0.01 csys =  0.39 CPU)
    Result: PASS

=head1 Event Hooks

There are various points in the test script where we might want to perform
some actions: Reset a test database, create a temp file, or otherwise set up
prerequisites for a test. C<Test::Class::MOP> provides some hooks that allow
us to perform actions at these points.

=head2 test_startup / test_shutdown

C<test_startup> is run as the very first thing in our test class, and is run only
once per test class. This allows us to set up some global things, like a
database that will be used throughout the entire test.

C<test_shutdown> is run once as the very last thing in our test class, and is
run only once per test class. This allows us to clean up things from
C<test_startup>, and also test to verify that anything from C<test_startup>
looks exactly as it should before we clean it up.

=head2 test_setup / test_teardown

What C<test_startup> and C<test_shutdonw> are for the entire test class,
C<test_setup> and C<test_teardown> are for every single C<test_*> method.

C<test_setup> is run before every test method. For canonical unit testing,
this is where you can create the things you need for each test, such as a log
file, rebuilding fixtures, or starting a database transaction.

C<test_teardown> happens after every test, and is where you can clean up the
things created in C<test_setup>, such as ending the database transaction. Note
that some developers actually prefer their cleanup to happen in their
C<test_setup> method, prior to setting up the test. That sounds odd, but it
means that if a test method fails, you haven't yet cleaned up and can easily
inspect your test environment.

=head1 Test Class Composition

The most important reason to choose a class test over a procedural test (using
only C<Test::More>) is class composition. 

=head2 Inheritance

Since we're using C<MOP>, inheritance is as easy as:

    package TestsFor::My::Test::Class;
    use Test::Class::MOP;
    extends 'My::Test::Base';

C<Test::Class::MOP> even provides a shortcut:

    package TestsFor::My::Text::Class;
    use Test::Class::MOP => 'My::Test::Base';

If C<My::Test::Base> will not be testing anything itself, we do not put it in
C<t/lib/TestsFor>, instead we put it in C<lib> or C<t/lib> (depending on if we
want it to be part of the public set of modules or not). This will make sure
our test runner does not try to run our base class that doesn't test anything
concrete.

=head2 Roles

If your distribution uses roles, so should your tests. Like inheritance, roles
are added in the regular C<MOP> way:

    package TestsFor::My::Test::Class;
    use Test::Class::MOP;
    with 'My::Test::Role';

=head2 Organizing Your Tests

Test code should be held to the same standard as the rest of the code in your
distribution:

=over 4

=item Don't Repeat Yourself

Copy/paste code isn't okay in your module code, and it should not be okay in
your test code either! Refactor your tests to use roles or inheritance.

=back

=head1 Advanced Features

=head2 plan

If you need to prepare a plan for your tests, you can do so using the plan()
method:

    sub test_constructor {
        my ( $test, $report ) = @_;
        $test->plan( 1 ); # 1 test in this sub
        isa_ok My::Module->new, 'My::Module';
    }

Using the C<plan()> method, we can know exactly how many tests did not run if
the test method ends prematurely. Without it, we would only get the message
"No plan was seen", we would not know which tests were not run.

=head2 skip

We can use the C<test_startup> and C<test_setup> methods to skip tests that we
can't or don't want to run for whatever reason.

If we don't want to run a single test method, we can use the C<test_setup> method
and call the C<test_skip> method with the reason we're skipping the test.

    sub test_will_fail {
        my ( $test ) = @_;
        fail "This doesn't work!";
    }
    
    sub test_setup {
        my ( $test, $report ) = @_;
        if ( $report->name eq 'test_will_fail' ) {
            $test->test_skip( 'It doesn't work' );
        }
    }

If we don't want to run an entire class, we can use the C<test_startup> method
and the same C<test_skip> method with the reason we're skipping the test.

    sub test_startup {
        my ( $test, $report ) = @_;
        $test->test_skip( "The entire class doesn't work" );
    }

=head2 Run Specific Test Classes

One of the problems with having only one test script to run all the test
classes is when we're working directly with one test class we still have to
run all the other test classes.

To fix this problem, C<Test::Class::MOP> allows us to specify which specific
classes we want to run in its constructor:

    # t/test_class_tests.t
    use File::Spec::Functions qw( catdir );
    use FindBin qw( $Bin );
    use Test::Class::MOP::Load catdir( $Bin, 't', 'lib' );
    Test::Class::MOP->new(
        classes => [ 'TestsFor::My::Test::Class' ],
    )->runtests;

Now, we only run C<TestsFor::My::Test::Class> instead of all the tests found in
C<TestsFor::>.

This isn't very elegant though, since we have to edit C<t/test_class_tests.t>
every time we want to run a new test. So, C<Test::Class::MOP> can also
accept which test classes to run via C<@ARGV>:

    # t/test_class_tests.t
    use File::Spec::Functions qw( catdir );
    use FindBin qw( $Bin );
    use Test::Class::MOP::Load catdir( $Bin, 't', 'lib' );
    Test::Class::MOP->new( classes => \@ARGV )->runtests;

If C<@ARGV> is empty, C<Test::Class::MOP> will run all classes. To give
arguments while running C<prove>, we use the arisdottle C<::>:

    prove -lb t/test_class_tests.t :: My::Test::Class

Now we can choose which test class we want to run right on the command line.

=head1 Tags

Tags are a way of organizing your test methods into groups. Later you can
choose to only execute the test methods from one or more tags. You can add
tags like "online" for tests that require a network, or "database" for tests
that require a database, and then include or exclude those tags when you
execute your tests.

You add tags to your test methods using attributes:

    sub test_database :Tags( database ) { ... }
    sub test_network :Tags( online ) { ... }

Then, if your database goes down, you can exclude those tests from the
C<t/test_class_tests.t> script:

    # t/test_class_tests.t
    use File::Spec::Functions qw( catdir );
    use FindBin qw( $Bin );
    use Test::Class::MOP::Load catdir( $Bin, 't', 'lib' );
    Test::Class::MOP->new(
        classes      => \@ARGV,
        exclude_tags => [qw( database )],
    )->runtests;

By adding tags to your tests, you can run only those tests that you
absolutely need to, increasing your productivity.

=head1 Boilerplate

Here is the bare minimum you need to get started using C<Test::Class::MOP>

=head2 Test Class

    # t/lib/TestsFor/My/Class.pm
    package TestsFor::My::Class;
    use Test::Class::MOP;

    sub test_something {
        pass "I tested something!";
    }

    1;

=head2 Test Runner

    # t/test_class_tests.t
    use File::Spec::Functions qw( catdir );
    use FindBin qw( $Bin );
    use Test::Class::MOP::Load catdir( $Bin, 't', 'lib' );
    Test::Class::MOP->new(
        classes => \@ARGV,
    )->runtests;

=head1 AUTHOR

Doug Bell: https://github.com/preaction
