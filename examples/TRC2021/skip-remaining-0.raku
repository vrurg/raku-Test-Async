use v6;
use Test::Async;

plan 10;

for ^5 { pass "good one $_" }

skip-remaining "let's assume they aren't implemented";

for ^5 { flunk "bad one $_" }

done-testing;
