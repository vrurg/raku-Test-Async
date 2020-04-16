use v6;
use nqp;
use Test::Async::Metamodel::HubHOW;
use Test::Async::Metamodel::BundleHOW;
use Test::Async::Metamodel::ReporterHOW;
use Test::Async::TestTool;

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

sub EXPORT {
    use NQPHLL:from<NQP>;
    my role TestAsyncGrammar {
        token package_declarator:sym<test-hub> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'test-hub';
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            <sym><.kok> <package_def>
            <.set_braid_from(self)>
        }
        token package_declarator:sym<test-bundle> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'role';
            :my $*TEST-BUNDLE-TYPE;
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            <sym><.kok>
            { $*LANG.set_how('role', Test::Async::Metamodel::BundleHOW); }
            <package_def>
            <.set_braid_from(self)>
            { # XXX Possible problem if package_def fails - not sure if role's HOW would be restored.
              $*LANG.set_how('role', Metamodel::ParametricRoleHOW); }
        }
        token package_declarator:sym<test-reporter> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'role';
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            :my $*TEST-BUNDLE-TYPE;
            <sym><.kok>
            { $*LANG.set_how('role', Test::Async::Metamodel::ReporterHOW); }
            <package_def>
            <.set_braid_from(self)>
            { # XXX Possible problem if package_def fails - not sure if role's HOW would be restored.
              $*LANG.set_how('role', Metamodel::ParametricRoleHOW); }
        }
    }

    my role TestAsyncActions {
        sub mkey ( Mu $/, Str:D $key ) {
            nqp::atkey(nqp::findmethod($/, 'hash')($/), $key)
        }

        method add_phaser(Mu $/) {
            my $blk := QAST::Block.new(
                QAST::Stmts.new,
                QAST::Stmts.new(
                    QAST::Op.new(
                        :op<callmethod>,
                        :name<register-bundle>,
                        QAST::WVal.new(:value(Test::Async::Metamodel::HubHOW)),
                        QAST::WVal.new(:value($*TEST-BUNDLE-TYPE))
                    )
                )
            );
            $*W.add_phaser($/, 'ENTER', $*W.create_code_obj_and_add_child($blk, 'Block'));
        }

        method package_declarator:sym<test-hub>(Mu $/) {
            $/.make( mkey($/, 'package_def').ast );
        }
        method package_declarator:sym<test-bundle>(Mu $/) {
            self.add_phaser($/);
            $/.make(mkey($/, 'package_def').ast);
        }
        method package_declarator:sym<test-reporter>(Mu $/) {
            self.add_phaser($/);
            $/.make(mkey($/, 'package_def').ast);
        }
    }

    unless $*LANG.^does( TestAsyncGrammar ) {
        $*LANG.set_how('test-hub', Test::Async::Metamodel::HubHOW);
        $ = $*LANG.define_slang(
            'MAIN',
            $*LANG.HOW.mixin($*LANG.WHAT,TestAsyncGrammar),
            $*LANG.actions.^mixin(TestAsyncActions)
        );
    }

    Map.new: ( EXPORT::DEFAULT:: )
}
