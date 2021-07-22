use v6;
use Test::Async <Base When>;

plan :when(:module<It::Doesnt::Exists>);

pass "you won't see this";
