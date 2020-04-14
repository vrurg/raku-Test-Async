use v6;
use nqp;
use Test::Async::Metamodel::HubHOW;
use Test::Async::Metamodel::BundleHOW;
use Test::Async::Metamodel::ReporterHOW;
use Test::Async::TestTool;

my package EXPORTHOW {
    package DECLARE {
        constant test-hub = Test::Async::Metamodel::HubHOW;
        constant test-bundle = Test::Async::Metamodel::BundleHOW;
        constant test-reporter = Test::Async::Metamodel::ReporterHOW;
    }
}

multi trait_mod:<is>(Method:D \meth, :$test-tool!) is export {
    my $tool-name = meth.name;
    my $readify = True;
    my $skippable = True;
    given $test-tool {
        when Str:D {
            $tool-name = $_;
        }
        when Hash:D | Pair:D {
            $tool-name = $_ with .<name>;
            $readify = $_ with .<readify>;
            $skippable = $_ with .<skip> // .<skippable>;
        }
        default {
            $tool-name = meth.name;
        }
    }
    meth does Test::Async::TestTool;
    meth.set-tool-name($tool-name);
    meth.set-readify($readify);
    meth.set-skippable($skippable);
}
