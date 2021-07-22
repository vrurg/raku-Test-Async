use v6;
use Test::Async <Base When>;

plan :when(
    :any(
        <force>,
        :module<It::Doesnt::Exists>,
    )
);

pass "test it";
use-ok 'It::Doesnt::Exists', "module loads ok";
