use v6;
use Test::Async;

plan :parallel;

my @ready;
my $starter = Promise.new;

for ^5 -> $n {
    @ready[$n] = Promise.new;
    subtest "Subtest $n" => {
        @ready[$n].keep;
        await $starter;
        #sleep .1.rand;
        note "########## $n";
        pass "all is good";
    }
}

await @ready;
pass "all subtests are ready";
$starter.keep;

done-testing;
