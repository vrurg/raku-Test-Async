use v6;
use Test::Async;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';

my @tests =
    [q<is "a", "a", "Str match";>, { :exitcode(0), :out("ok 1 - Str match\n1..1\n") }],
    [q<is Mu, Mu, "Mu:U match";>, { :exitcode(0), :out("ok 1 - Mu:U match\n1..1\n") }],
    [q<is Int, Int, "Int:U match";>, { :exitcode(0), :out("ok 1 - Int:U match\n1..1\n") }],
    [q<is 42, 42, "42 match";>, { :exitcode(0), :out("ok 1 - 42 match\n1..1\n") }],
    [q<is Mu, Int, "Mu/Int";>, { :exitcode(1), :out(/:s^not ok 1 \- Mu\/Int\n\# Failed test \'Mu\/Int\'\n/) }],
    [q<is Int, Mu, "Int/Mu";>, { :exitcode(1), :out(/:s^not ok 1 \- Int\/Mu\n\# Failed test \'Int\/Mu\'\n/) }],
    [q<is "a", 42, "Str:D/Int:D";>, { :exitcode(1), :out(/:s^not ok 1 \- Str\:D\/Int\:D\n\# Failed test \'Str\:D\/Int\:D\'\n/) }],
    [q<is "foo", "foo ", "str with space mismatch";>, { :exitcode(1), :out(/:s^not ok 1 \- str with space mismatch\n\# Failed test \'str with space mismatch\'\n/) }],
    [q<isnt 13, 42, "13 != 42";>, { :exitcode(0), :out("ok 1 - 13 != 42\n1..1\n") }],
    [q<isnt Mu, Int, "Mu != Int";>, { :exitcode(0), :out("ok 1 - Mu != Int\n1..1\n") }],
    [q<isnt Int, Mu, "Int != Mu";>, { :exitcode(0), :out("ok 1 - Int != Mu\n1..1\n") }],
    [q<isnt Mu, Mu, "Mu is Mu";>, { :exitcode(1), :out(/:s^not ok 1 \- Mu is Mu\n\# Failed test \'Mu is Mu\'\n/) }],
    [q<isnt Int, 42, "Int != 42";>, { :exitcode(0), :out("ok 1 - Int != 42\n1..1\n") }],
    [q<isnt "a", "a", "eqv. strings";>, { :exitcode(1), :out(/:s^not ok 1 \- eqv\. strings\n\# Failed test \'eqv\. strings\'\n/) }],
    [q<isnt Str, Int, "Str != Int";>, { :exitcode(0), :out("ok 1 - Str != Int\n1..1\n") }],
    ;

plan +@tests;

for @tests -> @test {
    is-run @test[0], @test[0], :compiler-args(@default-args), |@test[1];
}
