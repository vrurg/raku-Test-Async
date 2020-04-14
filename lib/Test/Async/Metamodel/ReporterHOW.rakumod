use v6;
unit class Test::Async::Metamodel::ReporterHOW;

use Test::Async::Metamodel::BundleHOW;
use Test::Async::Reporter;

also is Test::Async::Metamodel::BundleHOW;

method new_type(|) {
    my \reporter-class = callsame;
    reporter-class.^add_role(Test::Async::Reporter);
    reporter-class
}
