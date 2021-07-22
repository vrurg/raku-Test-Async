use v6;
use Test::Async;

for ^5 -> $n {
    subtest "Subtest $n" => {
        note "#------ $n";
        pass "all is good";
    }
}
