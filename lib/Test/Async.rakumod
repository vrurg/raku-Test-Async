use v6;


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
        ($*TEST-SUITE // Test::Async::Hub.top-suite).anchor: { $wrappee(|args) }
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
