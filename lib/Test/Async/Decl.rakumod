use v6;


use nqp;
use Test::Async::Metamodel::HubHOW;
use Test::Async::Metamodel::BundleHOW;
use Test::Async::Metamodel::ReporterHOW;
use Test::Async::TestTool;

my constant %aliases = :skip<skippable>, :wrap<wrappable>, :name<tool-name>, :anchor<anchoring>;

multi sub trait_mod:<is>(Method:D \meth, :$test-tool!) is export {
    my %p = tool-name => meth.name, :readify, :skippable, :wrappable, :!anchoring;
    if $test-tool ~~ Str:D {
        %p<tool-name> = $test-tool;
    }
    elsif $test-tool ~~ Positional | Iterable | Associative {
        my %tt = |$test-tool;
        for %tt.keys -> $param {
            if $param ~~ any(<name readify skip skippable wrap wrappable anchor anchoring>) {
                %p{%aliases{$param} // $param} = %tt{$param};
            }
            else {
                die "Unknown tool-name trait parameter '$param'"
            }
        }
    }
    meth does Test::Async::TestTool;
    for %p.keys -> $key {
        meth."set-$key"(%p{$key});
    }
}

sub EXPORT is raw {
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
            :my $*TEST-RESTORE-PACKAGE := True;
            <sym><.kok>
            { $*LANG.set_how('role', Test::Async::Metamodel::BundleHOW); }
            <package_def>
            <.set_braid_from(self)>
        }
        token package_declarator:sym<test-reporter> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'role';
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            :my $*TEST-BUNDLE-TYPE;
            :my $*TEST-RESTORE-PACKAGE := True;
            <sym><.kok>
            { $*LANG.set_how('role', Test::Async::Metamodel::ReporterHOW); }
            <package_def>
            <.set_braid_from(self)>
        }

        # set_package is been called right after a package is created. At this point we don't need to override role's
        # HOW anymore.
        method set_package(|) {
            if $*TEST-RESTORE-PACKAGE {
                $*LANG.set_how('role', Metamodel::ParametricRoleHOW);
                $*TEST-RESTORE-PACKAGE := False;
            }
            nextsame
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
