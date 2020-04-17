use v6;
unit class Test::Async::Metamodel::HubHOW is Metamodel::ClassHOW;
use nqp;
use Test::Async::Metamodel::BundleClassHOW;
my $suite;
my $suite-class;

my $bundle-typeobjs;
my %bundles;
method register-bundle(Mu \bundle-typeobj) {
    if $suite {
        warn "It is too late to register bundle " ~ bundle-typeobj.^name ~ ": suite has been constructed already";
        return;
    }
    my $bundle-name = bundle-typeobj.^name;
    return if %bundles{$bundle-name};
    %bundles{$bundle-name} := 1;
    nqp::unless(nqp::isconcrete($bundle-typeobjs), ($bundle-typeobjs := nqp::list()));
    nqp::unshift($bundle-typeobjs, bundle-typeobj);
}

method construct-suite(\hub-class) is raw {
    # Suite has been constructed already.
    if $suite {
        return hub-class ~~ $suite-class ?? hub-class !! $suite-class;
    }
    my $name = S/\:\:Hub$/\:\:Suit/ given hub-class.^name;
    my \suite-class = ::?CLASS.new_type(:$name);
    my \how = suite-class.HOW;
    $suite = True;
    my $last-parent := hub-class;
    if nqp::defined($bundle-typeobjs) {
        for ^nqp::elems($bundle-typeobjs) -> $i {
            my \bundle-typeobj = nqp::atpos($bundle-typeobjs, $i);
            my $class-name = bundle-typeobj.^name ~ "_class";
            my \bundle-class = Test::Async::Metamodel::BundleClassHOW.new_type(name => $class-name);
            bundle-class.^add_role(bundle-typeobj);
            bundle-class.^add_parent($last-parent);
            bundle-class.^compose;
            $last-parent := bundle-class;
        }
    }
    how.add_parent(suite-class, $last-parent);
    $suite-class := suite-class.^compose;
}

method suite(\type-obj) { $suite }
method suite-class(\type-obj) { self.construct_suite(type-obj) }
method bundles { nqp::defined($bundle-typeobjs) ?? $bundle-typeobjs !! nqp::list() }
