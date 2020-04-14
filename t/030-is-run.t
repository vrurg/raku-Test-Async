use v6;
use Test::Async;

plan 1;

is-run q<say "ok">,
    "is-run with simple code",
    :out("ok\n");

done-testing;
