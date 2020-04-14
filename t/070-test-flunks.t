use v6;
use Test::Async;
use Test::Async::Event;

plan 5;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';

subtest "Basic" => {
    plan 3;
    test-flunks "basic cases", 3;
    flunk "flunk tool";
    ok False, "ok with False";
    is 0, 1, "mismatching is";
}

subtest "With a skip" => {
    plan 3;
    test-flunks "skip is ok", 3;
    flunk "flunk 1";
    skip "one to skip";
    flunk "flunk 3";
}

subtest "With a skip-rest" => {
    plan 4;
    test-flunks "skip-rest doesn't break", 4;
    flunk "flunk 1";
    flunk "flunk 2";
    skip-remaining "test passing but it shouldn't";
    pass "pass 1";
    pass "pass 2";
}

subtest "With TODO" => {
    plan 4;
    test-flunks "todo doesn't break", 4;
    flunk "flunk 1";
    flunk "flunk 2";
    todo-remaining "test passing but it shouldn't";
    pass "pass 1";
    pass "pass 2";
}

subtest "With false-positives" => {
    plan 1;
    is-run q:to/TEST-CODE/, "pass causes failure",
           plan 1;
           test-flunks "will fail";
           pass "you shall not!";
           TEST-CODE
           :compiler-args(@default-args),
           :exitcode(1),
           :err(''),
           :out(/
                ^  "1..1\n"
                ^^ "not ok 1 - you shall not!\n"
                .*
                ^^ "# NOT FLUNK: will fail\n"
                ^^ "#     Cause: Test passed"
           /);
}

done-testing;
