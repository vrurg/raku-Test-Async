use v6;
# BEGIN {
# use Test::Async::Decl;
# test-bundle MyTests {
#     method is-foo is test-tool<is_foo> {
#         note "is it foo?";
#     }
# }
# }
# use Test::Async::Reporter::TAP;
use Test::Async;

plan 5;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';
# is-run has been checked to work in 005-bootstrap.t. Use it to diagnose
is-run q<pass "test passes">, "simple pass test, plan is output at the end",
        :compiler-args(@default-args),
        :out("ok 1 - test passes\n1..1\n");

is-run q<plan 1; pass "test passes">, "simple pass test, plan is output at the start",
        :compiler-args(@default-args),
        :out("1..1\nok 1 - test passes\n");

is-run q<pass "test passes"; done-testing; pass "not allowed">, "no testing beyond done-testing",
        :compiler-args(@default-args),
        :out("ok 1 - test passes\n1..1\n"),
        :err(/:s^^A test tool called after done\-testing /);

is-run q<flunk "test fails">, "test fails, plan is at the end",
        :compiler-args(@default-args),
        :out("not ok 1 - test fails\n# Failed test 'test fails'\n# at -e line 1\n1..1\n# You failed 1 test of 1\n"),
        :exitcode(1);

is-run q<flunk "test 1"; flunk "test 2";>, "exit code reflects the number of tests failed",
        :compiler-args(@default-args),
        :exitcode(2);

# plan 6,
#     # :parallel,
#     :random,
#     # todo => "later!",
#     # :skip-all("no reason"),
#     ;
#
# subtest "first child" => {
#     plan 3;
#     # sleep 2;
#     pass "WOW!";
#     flunk "WOW AGAIN!";
#     subtest "first child of the first" => {
#         pass "YES, YES!";
#     }
# };
#
# subtest "second child" => {
#     plan 2;
#     # sleep 1;
#     pass "WOW!";
#     subtest "first child of the second" => {
#         pass "YES, YES!";
#     }
# };
#
# skip "tst";
# pass "YEP?";
# # skip-rest "some check failed";
# flunk "nope!";
# ok (1.rand < 0.5), "flapping test";
# diag "test\ns;sldfk sflksjfd sdf;jls df;";
#
# done-testing;
