use v6;
use Test::Async;

plan 5, :random;
#plan 5, :random, :parallel;

class Foo {
    my atomicint $next-id = 0;
    has $.id = ++⚛$next-id;
    has Int:D $.n is required;
    method delta(--> UInt:D) { $!id - $!n }
}

for ^5 -> $n {
    subtest "Attempt $n" => {
        lives-ok { Foo.new(:$n).delta }, "sequencing";
    }
}
