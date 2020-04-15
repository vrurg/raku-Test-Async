use v6;
use nqp;
unit class Test::Async::Metamodel::HubHOW is Metamodel::ClassHOW;
has $!suite;

my $bundle-classes;
my %bundles;
method register-bundle(Mu \bundle-class) {
    my $bundle-name = bundle-class.^name;
    return if %bundles{$bundle-name};
    %bundles{$bundle-name} := 1;
    nqp::unless(nqp::isconcrete($bundle-classes), ($bundle-classes := nqp::list()));
    nqp::unshift($bundle-classes, bundle-class);
}

method construct_suite(\hub-class) is raw {
    # Suite has been constructed already.
    return hub-class if hub-class.^suite;
    my $name = S/\:\:Hub$/\:\:Suit/ given hub-class.^name;
    my \suite-class = ::?CLASS.new_type(:$name);
    my \how = suite-class.HOW;
    how.set_suite(True);
    for ^nqp::elems($bundle-classes) -> $i {
        my \bundle-class = nqp::atpos($bundle-classes, $i);
        how.add_parent(suite-class, bundle-class);
    }
    how.add_parent(suite-class, hub-class);
    suite-class.^compose;
    suite-class
}

method set_suite($is-set) { $!suite = $is-set }
method suite(\type-obj) { $!suite }
method bundles { $bundle-classes // () }
