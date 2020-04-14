use v6;
unit module Test::Async::Utils;
use nqp;
use Test::Async::Result;

enum TestMode   is export <TMAsync TMSequential TMRandom>;
enum TestStage  is export <TSInitializing TSInProgress TSFinishing TSDismissed>;
# This is used to inform send-test what statistics counter it must update.
# We cannot rely on event type for this because custom bundles could define their own events.
enum TestResult is export <TRFailed TRPassed TRSkipped>;

sub test-result(Bool(Mu) $cond, *%c) is export {
    # note "test-result fail: ", $fail.raku;
    my %profile;
    for <fail success> {
        next unless %c{$_};
        %profile{$_ ~ "-profile"} = %c{$_}.map({ .key => .value<> }).Capture;
    }
    Test::Async::Result.new: :$cond, |%profile
}

sub stringify(Mu $obj is raw --> Str:D) is export {
    (try $obj.raku if nqp::can($obj, 'raku'))
        // ($obj.gist if nqp::can($obj, 'gist'))
        // ($obj.HOW.name($obj) if nqp::can($obj.HOW, 'name'))
        // '?'
}
