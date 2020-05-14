use v6;
use Test::Async;

plan 8;

dies-ok { die "foo" }, "code dies ok";
lives-ok { ++$ }, "code lives ok";
eval-dies-ok 'die "in EVAL"', "EVAL'ed code dies ok";
eval-lives-ok 'my $foo = 42', "EVAL'ed code lives ok";

test-flunks 4;
dies-ok { ++$ }, "does-ok flunks on surviving code";
lives-ok { die "dying on purpose" }, "lives-ok flunks on dying code";
eval-dies-ok 'my $foo = 42', "eval-dies-ok flunks on surviving code";
eval-lives-ok 'die "die in EVAL"', "eval-lives-ok flunks on dying code";

done-testing;
