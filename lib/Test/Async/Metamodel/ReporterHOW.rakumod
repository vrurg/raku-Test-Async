use v6;
unit class Test::Async::Metamodel::ReporterHOW;

use Test::Async::Metamodel::BundleHOW;
use Test::Async::Reporter;

also is Test::Async::Metamodel::BundleHOW;

method new_type(|) {
    my \reporter-typeobj = callsame;
    reporter-typeobj.^add_role(Test::Async::Reporter);
    reporter-typeobj
}
