use v6;
use Test::Async;

plan 5, :random;

for ^4 -> $n {
    subtest "test $n" => {
        plan 1;
        pass "all good";
    }
}

pass "MAIN WORKS";

done-testing;
