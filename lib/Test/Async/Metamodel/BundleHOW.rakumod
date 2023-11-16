use v6;


unit class Test::Async::Metamodel::BundleHOW is Metamodel::ParametricRoleHOW;
use Test::Async::Metamodel::HubHOW;

method new_type(|) {
    $*TEST-BUNDLE-TYPE := callsame;
    unless $*W && $*W.is_precompilation_mode {
        Test::Async::Metamodel::HubHOW.register-bundle: $*TEST-BUNDLE-TYPE;
    }
    $*TEST-BUNDLE-TYPE
}
