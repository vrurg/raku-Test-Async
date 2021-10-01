use v6;
use Test::Async;

# Randomization helps to locate a problem where attribute $!n
# is set in order different to that of $!id causing method delta
# to sometimes return an illegal negative value.

#plan 5, :random;
plan 5, :random, :parallel;

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
