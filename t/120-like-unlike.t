use v6;
use Test::Async;

plan 2;

subtest "like basics" => {
    plan 4;
    # https://github.com/rakudo/rakudo/issues/1567
    like 42, /42/, '`like` can accept non-Str objects (Int)';
    like class { method Str { 'foo' } }, /foo/,
        '`like` can accept non-Str objects (custom)';

    test-flunks 2;
    like "foo", /bar/, "foo does't match /bar/";
    like 42, /43/, "non-Str object no-match flunks";
}

subtest "unlike basics" => {
    # https://github.com/rakudo/rakudo/issues/1567
    unlike 42, /43/, '`unlike` can accept non-Str objects (Int)';
    unlike class { method Str { 'foo' } }, /bar/,
        '`unlike` can accept non-Str objects (custom)';

    test-flunks 2;
    unlike "foo", /foo/, "foo matches /foo/";
    unlike pi, /"3.1415926"/, "non-Str object match flunks";
}

done-testing;
