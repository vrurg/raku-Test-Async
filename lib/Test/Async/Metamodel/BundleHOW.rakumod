use v6;
use Test::Async::Metamodel::HubHOW;
unit class Test::Async::Metamodel::BundleHOW is Metamodel::ClassHOW;

method new_type(|) {
    my \bundle-class = callsame;
    $*W.add_phaser($*LANG, 'ENTER', { Test::Async::Metamodel::HubHOW.register-bundle: bundle-class });
    bundle-class
}

# method compose(Mu \obj, |c) {
#     note "- composing bundle ", obj.^name;
#     nextsame;
# }
