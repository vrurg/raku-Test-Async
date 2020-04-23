use v6;
use Test::Async;

plan 6;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';
# is-run has been checked to work in 005-bootstrap.t. Use it to diagnose
is-run q<pass "test passes">, "simple pass test, plan is output at the end",
        :compiler-args(@default-args),
        :out("ok 1 - test passes\n1..1\n"),
        :err('');

is-run q<plan 1; pass "test passes">, "simple pass test, plan is output at the start",
        :compiler-args(@default-args),
        :out("1..1\nok 1 - test passes\n")
        :err('');

is-run q<pass "test passes"; done-testing; pass "not allowed">, "no testing beyond done-testing",
        :compiler-args(@default-args),
        :out("ok 1 - test passes\n1..1\n"),
        :err(/:s^^A test tool called after done\-testing /);

is-run q<flunk "test fails">, "test fails, plan is at the end",
        :compiler-args(@default-args),
        :out("not ok 1 - test fails\n# Failed test 'test fails'\n# at -e line 1\n1..1\n# You failed 1 test of 1\n"),
        :err(''),
        :exitcode(1);

is-run q<flunk "test 1"; flunk "test 2";>, "exit code reflects the number of tests failed",
        :compiler-args(@default-args),
        :err(''),
        :exitcode(2);

is-run q:to/TEST_CODE/, "two plans result in bail out",
            plan 4; plan 2;
            TEST_CODE
        :compiler-args(@default-args),
        :out("1..4\n# FAILURE: It is too late to change plan at -e at line 1\n# You planned 4 tests, but ran 0\n# You failed 4 tests of 0\n"),
        :err(''),
        :exitcode(4); # Exit code is the number of initially planned tests

done-testing;
