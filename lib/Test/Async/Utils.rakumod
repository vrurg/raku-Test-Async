use v6;

=begin pod
=NAME

C<Test::Async::Utils> - C<Test::Async> utilities

=head1 EXPORTED ENUMS

=head2 C<TestMode>

Suite mode of operation:

=item C<TMSequential> - all child suites are invoked sequentially as appear in the code
=item C<TMAsync> – child suites are invoked asynchronously as appear in the code
=item C<TMRandom> - child suites are invoked in random order after the suite code is done

=head2 C<TestStage>

Suite lifecycle stages: C<TSInitializing>, C<TSInProgress>, C<TSFinishing>, C<TSFinished>, C<TSDismissed>.

=head2 C<TestResult>

Test outcome codes: C<TRPassed>, C<TRFailed>, C<TRSkipped>

=head1 EXPORTED ROUTINES

=head2 C<test-result(Bool $cond, :$fail, :$success --> Test::Async::Result)>

Creates a L<C<Test::Async::Result>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Result.md>
object using the provided parameters. C<$fail> and C<$success> are shortcut names for corresponding C<-profile>
attributes of C<Test::Async::Result> class.

=head2 C<stringify(Mu \obj --> Str:D)>

Tries to stringify the C<obj> in the most appropriate way. Use it to unify the look of test comments.

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit module Test::Async::Utils;
use nqp;
use Test::Async::Result;

enum TestMode   is export <TMAsync TMSequential TMRandom>;
enum TestStage  is export «TSInitializing TSInProgress TSFinishing TSFinished TSDismissed TSFatality»;
# This is used to inform send-test what statistics counter it must update.
# We cannot rely on event type for this because custom bundles could define their own events.
enum TestResult is export <TRFailed TRPassed TRSkipped>;

class ToolCallerCtx is export {
    my subset CALLER-CTX of Any where Stash:D | PseudoStash:D;

    has CallFrame:D $.frame is required;
    has CALLER-CTX $.stash is required;
    # If anchored then for any nested too call locate-tool-caller will return the anchored location.
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
