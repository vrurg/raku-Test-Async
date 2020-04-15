use v6;
use Test::Async::Metamodel::HubHOW;
use Test::Async::Hub;
use Test::Async::Reporter;
use Test::Async::TestTool;

module Test::Async:ver<0.0.1> {
    our sub test-suite is export {
        once require ::('Test::Async::Hub');
        $*TEST-SUITE // ::('Test::Async::Hub').top-suite
    }
}

sub EXPORT(*@b) {
    $*W.add_phaser($*LANG, 'END', my &phaser = { 
        CATCH {
            note "===SORRY! SUIT SHUTDOWN===\n", $_;
            exit 255;
        }
        Test::Async::Hub.top-suite.done-testing 
    });
    $*W.add_object_if_no_sc(&phaser);
    my @bundles = (Test::Async::Hub.HOW.bundles.map(*.^name), @b).flat;
    @bundles = (<Base>) unless @bundles;
    my $has-reporter;
    for Test::Async::Metamodel::HubHOW.bundles -> \bundle-class {
        if bundle-class ~~ Test::Async::Reporter {
            $has-reporter = True;
            last;
        }
    }
    @bundles.push: 'Test::Async::Reporter::TAP' unless $has-reporter;
    for @bundles {
        my $bundle = .index('::') ?? $_ !! 'Test::Async::' ~ $_;
        require ::($bundle);
    }
    Map.new( |Test::Async::Hub.top-suite.tool-factory )
}

END {
    my $hub = Test::Async::Hub.top-suite;
    my $exit-code = $hub.tests-failed min 254;
    unless $exit-code {
        $exit-code = 255
            if ($hub.planned.defined && $hub.tests-run) && (($hub.planned // 0) != ($hub.tests-run // 0));
    }
    exit $exit-code;
}
