use v6;
use Test::Async;

plan 3;

subtest "Basics" => {
    plan 4;
    dies-ok { die "foo" }, "code dies ok";
    lives-ok { ++$ }, "code lives ok";
    eval-dies-ok 'die "in EVAL"', "EVAL'ed code dies ok";
    eval-lives-ok 'my $foo = 42', "EVAL'ed code lives ok";
}

subtest "Flunking" => {
    plan 4;
    test-flunks 4;
    dies-ok { ++$ }, "does-ok flunks on surviving code";
    lives-ok { die "dying on purpose" }, "lives-ok flunks on dying code";
    eval-dies-ok 'my $foo = 42', "eval-dies-ok flunks on surviving code";
    eval-lives-ok 'die "die in EVAL"', "eval-lives-ok flunks on dying code";
}

subtest "Contextual" => {
    plan 3;
    my $bar = pi;
    { # The inner block is needed to prevent $bar from being lowered away by optimizer.
        is $bar, pi, "control test";
        eval-lives-ok q<$bar *= 2>, "evaling test sees a local variable";
        is $bar, pi * 2, "eval changed the local variable";
    }
}

done-testing;
