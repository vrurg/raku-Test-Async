use v6;
use Test::Async;

# Randomized subtests will be invoked at the end, after
# the rest of the top suite is executed.

plan 5, :random;

for ^4 -> $n {
    subtest "test $n" => {
        plan 1;
        pass "all good";
    }
}

pass "MAIN WORKS";

done-testing;
