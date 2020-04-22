use v6;
use Test::Async <When Base>;
use Test::Async::X;

plan 4;

# Delete and set environment variables to build the testing environment.
%*ENV<RELEASE_TESTING>:delete;
%*ENV<NETWORK_TESTING>:delete;
%*ENV<AUTHOR_TESTING> = 1;

subtest "Conditions" => {
    my $res;
    nok $res = test-requires(:all(<release>)), "no RELEASE_TESTING";
    is $res.message, '$RELEASE_TESTING', "no-match message for RELEASE_TESTING";
    ok test-requires(:all(<author>)), "have AUTHOR_TESTING";
    ok test-requires(<release>, :all(<author>)), "positionals treated as any, second sub-condition fulfilled";
    ok test-requires(<author>, :all(<release>)), "positionals again, first sub-condition fulfilled";
    nok $res = test-requires(:all(<author release>)), ":all() with one fail";
    is $res.message, '$RELEASE_TESTING', "no-match message for :all with a fail";
    nok $res = test-requires(:any(<release network>)), ":any with all failed conditions";
    is $res.message, 'any($RELEASE_TESTING, $NETWORK_TESTING)', "no-match message for :any with all failed";
    nok $res = test-requires(:module(<Test::Async::__NOMOD>)), "missing module";
    is $res.message, 'module(Test::Async::__NOMOD)', "no-match message for missing module";
    ok test-requires(:any(:module(<Test::Async::__NOMOD>), :module<Test::Async>)), ":any with one successfull module";
    nok $res = test-requires(:all(:module<Test::Async>, :module<Test::Async::__NOMOD1>, :module<Test::Async::__NOMOD2>)),
        ":all with non-existing modules";
    is $res.message, 'module(Test::Async::__NOMOD1)', "no-match message for :any with non-existing modules";
    nok $res = test-requires(:all(:any(:module<Test::Async::__NOMOD1>, :module<Test::Async::__NOMOD2>, <release>), :module<Test>)),
        ":all with nested failing :any";
    is $res.message, 'any(module(Test::Async::__NOMOD1), module(Test::Async::__NOMOD2), $RELEASE_TESTING)',
        "no-match message for :all with nested failing :any";
}

subtest "Errors" => {
    plan 1;
    throws-like { test-requires(:what<something>) },
                X::WhenCondition,
                "when with unknown condition throws",
                :message("Bad 'when' condition :what");
}

subtest "Plan 'when' condition skips" => {
    plan 2, :when(:any(<release network>));
    flunk "must not fail because 'when' would result in skipping this flunk";
    flunk "must not fail because 'when' would result in skipping this flunk";
}

subtest "Top suite 'when'" => {
    my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib');
    is-run q:to/TEST_CODE/, "'when' in a top suite plan",
                use Test::Async <When Base>;
                plan 4, :when(<release>);
                flunk "1. this flunk must be skipped";
                flunk "2. this flunk must be skipped";
                flunk "3. this flunk must be skipped";
                flunk "4. this flunk must be skipped";
                TEST_CODE
            :compiler-args(@default-args),
            :out("1..0 # Skipped: Unfulfilled when condition: \$RELEASE_TESTING\n# You planned 4 tests, but ran 0\n"),
            :err(''),
            :exitcode(0);
}

done-testing;
