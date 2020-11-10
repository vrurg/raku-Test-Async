use v6;
use Test::Async;

plan 2;

subtest "isa-ok basics" => {
    plan 9;
    isa-ok "foo", Str, "string object is Str";
    isa-ok 42, Cool, "Int is Numeric";
    isa-ok pi, Num, "pi is Num";

    isa-ok Any.HOW, Metamodel::ClassHOW, "Any.HOW is Metamodel::ClassHOW";
    isa-ok Numeric.HOW, Metamodel::ParametricRoleGroupHOW, "Numeric.HOW is Metamodel::ParametricRoleGroupHOW";
    isa-ok UInt.HOW, Metamodel::SubsetHOW, "UInt.HOW is Metamodel::SubsetHOW";
    my enum EE <a b c>;
    isa-ok EE.HOW, Metamodel::EnumHOW, "an enum HOW is Metamodel::EnumHOW";

    my class A::B::C {
    }
    my $obj = A::B::C.new;
    isa-ok $obj, "A::B::C", "isa-ok works with type names";

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
