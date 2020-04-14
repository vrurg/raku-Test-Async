use v6;
use Test::Async;

plan 2;

subtest "isa-ok basics" => {
    plan 4;
    isa-ok "foo", Str, "string object is Str";
    isa-ok 42, Cool, "Int is Numeric";
    isa-ok pi, Num, "pi is Num";

    test-flunks;
    isa-ok 42, Rat, "42 isn't Rat";
}

subtest "does-ok basics" => {
    plan 4;
    does-ok Int, Numeric;
    does-ok 42, Real;

    test-flunks 2;
    does-ok Str, Numeric;
    does-ok "foo", Real;
}

done-testing;
