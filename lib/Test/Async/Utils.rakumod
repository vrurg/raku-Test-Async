use v6;


unit module Test::Async::Utils;
use nqp;
use Test::Async::Result;

constant IS-NEWDISP-COMPILER is export = do {
    .version >= v2021.09.228.gdd.2.b.274.fd && .backend eq 'moar' given $*RAKU.compiler
};


enum TestMode   is export <TMAsync TMSequential TMRandom>;
enum TestStage  is export «TSInitializing TSInProgress TSFinishing TSFinished TSDismissed TSFatality»;
# This is used to inform send-test what statistics counter it must update.
# We cannot rely on event type for this because custom bundles could define their own events.
enum TestResult is export <TRFailed TRPassed TRSkipped>;

class ToolCallerCtx is export {
    my subset CALLER-CTX of Any where Stash:D | PseudoStash:D;

    has CallFrame:D $.frame is required;
    has CALLER-CTX $.stash is required;
    # If anchored then for any nested call locate-tool-caller will return the anchored location.
    has Bool:D $.anchored = False;
}

sub test-result(Bool(Mu) $cond, *%c) is export {
    # note "test-result fail: ", $fail.raku;
    my %profile;
    for <fail success> {
        next unless %c{$_};
        %profile{$_ ~ "-profile"} = %c{$_};
    }
    Test::Async::Result.new: :$cond, |%profile
}

sub stringify(Mu $obj is raw --> Str:D) is export {
    (try $obj.raku if nqp::can($obj, 'raku'))
        // ($obj.gist if nqp::can($obj, 'gist'))
        // ($obj.HOW.name($obj) if nqp::can($obj.HOW, 'name'))
        // '?'
}

our sub test-suite is export {
    require ::('Test::Async::Hub');
    ::('Test::Async::Hub').test-suite;
}
