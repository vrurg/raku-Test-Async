use v6;

=begin pod
=head1 NAME

C<Test::Async> - base module of the framework

=head1 SYNOPSIS

    use Test::Async;
    plan 1;
    pass "Hello World!";
    done-testing;

=head1 DESCRIPTION

The module setups testing evironment for a test suite. It is intended to be used in a script implementing the suite but
is not recommended for a module. See
L<C<Test::Async::CookBook>|Async/CookBook.md>
for more details.

=head2 Exports

The module re-exports all symbols found in a test bundle C<EXPORT::DEFAULT> package.

Also exports:

=head3 C<test-suite>

Return the test suite which is actual for the current context. The suite is looked up either in C<$*TEST-SUITE> or
via C<Test::Async::Hub> C<top-suite> method.

=head3 C<is test-assertion> or C<is test-tool>

A quick way to turn a C<routine> into test tool. This means, in particular, that for test tools, invoked from within
the routine, any error would be reported as if it is the test assertions flunked. For example, for the following test
suite:

=begin code
 1: use Test::Async;
 2: sub flunk-me(Str:D $message) is test-assertion {
 3:    subtest $message, :hidden, {
 4:        pass "oki";
 5:        flunk "I'm intentionally bad"
 6:    }
 7: }
 8: test-flunks "we need to see where it flunks";
 9: subtest "Flunking" => {
10:     flunk-me "need to.";
11: }
=end code

The output would contain something like:

=begin output
    # Failed test 'need to.'
    # at ...test-suite-path... line 10
=end output

The above example also uses the recommended practive of using a test assertion where, whenever it is calling 2 or more
test tools, a C<:hidden> C<subtest> would be wrapping around them in order to create common context.

=head3 Test Tools

The module exports all test tools it finds in the top suite object. See
L<C<Test::Async::Manual>|Async/Manual.md>
for more details.

=head1 SEE ALSO

L<C<Test::Async::Manual>|Async/Manual.md>,
L<C<Test::Async::CookBook>|Async/CookBook.md>,
L<C<Test::Async::Base>|Async/Base.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

module Test::Async:ver($?DISTRIBUTION.meta<ver>):api($?DISTRIBUTION.meta<api>):auth($?DISTRIBUTION.meta<auth>) {
    our sub META6 { $?DISTRIBUTION.meta }
}

use Test::Async::Hub;
use Test::Async::Utils;
use nqp;

multi sub trait_mod:<is>(Routine:D \routine, :test-tool(:$test-assertion)!) is export {
    my $wrappee := nqp::getattr(routine, Code, '$!do');
    my &wrapper := my sub (|args) is hidden-from-backtrace is raw {
        $wrappee := nextcallee() if IS-NEWDISP-COMPILER;
        $*TEST-SUITE.anchor: { $wrappee(|args) }
    }
    &wrapper.set_name(routine.name ~ ":<test-tool-wrapper>");
    routine.wrap(&wrapper);
}

sub EXPORT(*@b) is raw {
    my @bundles = (Test::Async::Hub.HOW.bundles, @b).flat;
    @bundles = (<Base>) unless @bundles;
    my $has-reporter;
    once require ::('Test::Async::Reporter');
    my @bundle_exports;
    for @bundles.grep(Str) {
        my $bundle = .index('::') ?? $_ !! 'Test::Async::' ~ $_;
        require ::($bundle);
        if (::<EXPORT>:exists) && (::("EXPORT").WHO<DEFAULT>:exists) {
            @bundle_exports.append: ::("EXPORT").WHO<DEFAULT>.WHO.pairs;
        }
    }
    for Test::Async::Hub.HOW.bundles -> \bundle-class {
        if bundle-class ~~ ::('Test::Async::Reporter') {
            $has-reporter = True;
            last;
        }
    }
    unless $has-reporter {
        require ::('Test::Async::Reporter::TAP')
    }
    Map.new(
        |@bundle_exports,
        |Test::Async::Hub.tool-factory,
        '&test-suite' => &Test::Async::Utils::test-suite,
    )
}

END {
    if Test::Async::Hub.has-top-suite {
        my $suite = Test::Async::Hub.top-suite;
        CATCH {
            default {
                $suite.fatality(255, exception => $_);
            }
        }
        # $suite.trace-out: "# ___ Test::Async END phaser, has top-suite";
        Test::Async::Hub.top-suite.done-testing;
        exit $suite.exit-code;
    }
}
