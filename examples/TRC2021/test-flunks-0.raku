use v6;
use Test::Async;

plan 2;

test-flunks "we expect it for flunk", 2;
is 13, 42, "it is intentionally wrong";
isa-ok "42", Int, "you shall not!..";

done-testing;
