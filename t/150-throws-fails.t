use v6;
use Test::Async;

plan 2;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';

my class X::TestError is Exception {
    has Str:D $.foo is required;
    has Int $.bar;
}

subtest "throws-like basics" => {
    plan 5;

    # Test for a bug where throws-like were dying on wrong exception if no matchers were used.
    is-run q:to/TESTCODE/,
            test-flunks "deliberate failure"; # Make sure the exit code is 0
            throws-like { (my class X::WrongException is Exception { method message {"irrelevant"} }).new.throw },
                        X::AdHoc;
            TESTCODE
        "throws-like without matchers doesn't die on fail",
        :exitcode(0),
        :out(/'code dies' .* 'wrong exception type' .* 'expected: X::AdHoc' .* 'got: X::WrongException'/),
        :err(""),
        :compiler-args(@default-args),
        :async;

    ok throws-like(
            { X::TestError.new(:foo("a data")).throw; },
            X::TestError,
            "custom exception throw",
            :foo(/data/),
            :bar(Int)
        ),
        "successfull throws-like returns True";

    test-flunks "anticipated failure", 1;
    my $rc = throws-like(
            { X::TestError.new(:foo("a data"), :bar(42)).throw; },
            X::TestError,
            "custom exception throw with failing matcher",
            :foo(/data/),
            :bar(13)
        );
    nok $rc, "failed throws-like returns False";
}

subtest "fails-like" => {
    plan 3;

    subtest 'Basics' => {
        plan 4;
        ok fails-like({ sub { fail }() }, Exception), "fails-like returns True on Failure";

        test-flunks;
        my $rc = fails-like { 42 }, Exception;
        nok $rc, "fails-like returns False when no Failure";
    }

    subtest 'Callable arg' => {
        plan 9;
        fails-like { sub { fail }() }, Exception;
        fails-like { sub { fail }() }, Exception, 'plain fail';
        fails-like {
            sub { fail X::Syntax::Reserved.new: :instead<foo>, :pos<bar> }()
        }, X::Syntax::Reserved, :instead<foo>, :pos<bar>, 'typed fail';

        fails-like {
            sub { fail X::Syntax::Reserved.new: :instead, :pos<bar> }()
        }, X::Syntax::Reserved, instead => * === True, 'whatever bool matcher';

        throws-like {
            fails-like {
                sub { fail X::Syntax::Reserved.new: :instead, :pos<bar> }()
            }, X::Syntax::Reserved, :instead;
        }, X::Match::Bool, message => *.contains('instead'), 'bool matcher throws';

        test-flunks 4;
        fails-like { sub { fail }().sink }, Exception, 'plain fail (thrown)';
        fails-like { (my $f := sub { fail }()).so; $f }, Exception, 'plain fail (handled)';
        fails-like {
            sub { fail X::Syntax::Reserved.new: :instead<foo>, :pos<bar> }().sink
        }, X::Syntax::Reserved, :instead<foo>, :pos<bar>, 'typed fail (thrown)';
        fails-like { 42 }, Exception, 'non-Failure return';
    }

    subtest 'Str arg' => {
        plan 9;
        fails-like ｢sub { fail }() ｣, Exception;
        fails-like ｢sub { fail }() ｣, Exception, 'plain fail';
        fails-like ｢
            sub { fail X::Syntax::Reserved.new: :instead<foo>, :pos<bar> }()
        ｣, X::Syntax::Reserved, :instead<foo>, :pos<bar>, 'typed fail';

        fails-like ｢
            sub { fail X::Syntax::Reserved.new: :instead, :pos<bar> }()
        ｣, X::Syntax::Reserved, instead => * === True, 'whatever bool matcher';

        throws-like {
            fails-like ｢
                sub { fail X::Syntax::Reserved.new: :instead, :pos<bar> }()
            ｣, X::Syntax::Reserved, :instead;
        }, X::Match::Bool, message => *.contains('instead'), 'bool matcher throws';


        test-flunks 4;
        fails-like ｢ sub { fail }().sink ｣, Exception, 'plain fail (thrown)';
        fails-like ｢ (my $f := sub { fail }()).so; $f ｣, Exception, 'plain fail (handled)';
        fails-like ｢
            sub { fail X::Syntax::Reserved.new: :instead<foo>, :pos<bar> }().sink
        ｣, X::Syntax::Reserved, :instead<foo>, :pos<bar>, 'typed fail (thrown)';
        fails-like ｢ 42 ｣, 'non-Failure return';
    }
}

done-testing;
