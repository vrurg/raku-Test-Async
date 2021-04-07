use v6;
use Test::Async;

plan 1;

subtest "can-ok basics" => {
    plan 3;

    can-ok Str, "Int";
    can-ok 42, "Str";

    test-flunks;
    can-ok Num, "make-it-long-and-impossible-method-name";
}

done-testing;
