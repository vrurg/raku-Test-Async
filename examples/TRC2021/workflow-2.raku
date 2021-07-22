use v6;
use Test::Async;

for ^3 -> $i {
    test-suite.start: {
        throws-like {
            die "oki";
        }, X::AdHoc, "tested $i";
    }
}

pass "all good";
