use v6;
use nqp;
use Test::Async::Metamodel::HubHOW;
unit class Test::Async::Metamodel::BundleHOW is Metamodel::ParametricRoleHOW;
use Test::Async::TestTool;
use Test::Async::Utils;

method new_type(|) {
    $*TEST-BUNDLE-TYPE := callsame
}
