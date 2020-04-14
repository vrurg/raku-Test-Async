use v6;
use Test::Async;

plan 3;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';

is-run q:to/TEST-CODE/, "plan skip counted",
       plan 3;
       pass "test 1";
       skip "test 2";
       pass "test 3";
       TEST-CODE
       :compiler-args(@default-args),
       :exitcode(0),
       :out(/^"1..3\nok 1 - test 1\nok 2 - # SKIP test 2\nok 3 - test 3\n"/);

is-run q:to/TEST-CODE/, "skip in plan",
       plan 2, :skip-all("this suite won't run");
       pass "test 1"; pass "test 2";
       TEST-CODE
   :compiler-args(@default-args),
   :exitcode(0),
   :out(/^"1..0 # Skipped: this suite won't run\n"/);

is-run q:to/TEST-CODE/, "skip-remaining",
       plan 3;
       pass "test 1";
       skip-remaining "these are irrelevant now";
       pass "test 2";
       pass "test 3";
       TEST-CODE
   :compiler-args(@default-args),
   :exitcode(0),
   :out("1..3\nok 1 - test 1\nok 2 - # SKIP these are irrelevant now\nok 3 - # SKIP these are irrelevant now\n");

done-testing;
