use v6;
use Test::Async;

plan 3;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';

is-run q:to/TEST-CODE/, "single todo",
       plan 1;
       todo "ignore error";
       flunk "failing test";
       TEST-CODE
       :compiler-args(@default-args),
       :exitcode(0),
       :err(''),
       :out(/^"1..1\nnot ok 1 - failing test # TODO ignore error\n"/);

is-run q:to/TEST-CODE/, "planned todo",
       plan 2, todo => "suit not ready";
       flunk "failing test";
       pass "passing test";
       TEST-CODE
       :compiler-args(@default-args),
       :exitcode(0),
       :err(''),
       :out(
            /^"1..2\nnot ok 1 - failing test # TODO suit not ready\n"
            .*
            ^^"ok 2 - passing test # TODO suit not ready"/
       );

is-run q:to/TEST-CODE/, "todo on remaining tests",
       plan 3;
       pass "step 1";
       todo-remaining "steps 2 and 3 not ready";
       flunk "step 2";
       flunk "step 3";
       TEST-CODE
       :compiler-args(@default-args),
       :exitcode(0),
       :err(''),
       :out(
            /^"1..3\nok 1 - step 1\n"
            .*
            ^^"not ok 2 - step 2 # TODO steps 2 and 3 not ready\n"
            .*
            ^^"not ok 3 - step 3 # TODO steps 2 and 3 not ready\n"
            /
       );
