use v6;
use Test::Async;

plan 3;

use-ok "Test::Async";
use-ok "newline", "a pargma is use-d ok";

test-flunks;
use-ok "Who-would-event-call-a-module-like-this::Impossible", "presumably non-existing module can't be use-d";

done-testing;
