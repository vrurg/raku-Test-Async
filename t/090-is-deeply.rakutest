use v6;
use Test::Async;

plan 4;

subtest "basic" => {
    plan 2;

    is-deeply
        [ 1..4 ], [ 1..4 ],
        "is-deeply (simple)";

    is-deeply
        { a => "b", c => "d", nums => [<1 2 3 4 5 6>.map( *.Str )] },
        { nums => ["1".."6"], <a b c d> },
        "is-deeply (more complex)";
}

subtest 'is-deeply with Seqs does not claim `Seq.new` expected/got' => {
    plan 4;

    is-deeply (1, 2).Seq, (1, 2).Seq, 'two Seqs, passing';
    test-flunks 3;
    is-deeply (1, 2).Seq, (1, 3).Seq, 'two Seqs, failing';
    is-deeply (1, 2).Seq, [1, 3], '`got` Seq, failing';
    is-deeply [1, 2], (1, 3).Seq, "`expected` Seq, failing";
}

subtest 'Junctions do not cause multiple tests to run' => {
    plan 2;
    is-deeply any(1, 2, 3), none(4, 5, 6), 'passing test';
    test-flunks;
    is-deeply 2, none(1, 2, 3), "failing test";
}

subtest 'can test Seq type objects' => {
    plan 3;
    is-deeply Seq, Seq, 'Seq, Seq';
    test-flunks 2;
    is-deeply Seq, 42, "Seq, 42";
    is-deeply 42, Seq, "42, Seq";
}

done-testing;
