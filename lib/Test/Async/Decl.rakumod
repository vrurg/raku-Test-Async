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

    # The `unit test-hub|test-bundle|test-reporter` declarators for the
    # RakuAST grammar. `test-hub` gets its own declarator HOW; `test-bundle`
    # and `test-reporter` reuse the `role` declarator with its HOW swapped
    # for the declaration, restored in `set_package`.
    my role TestAsyncGrammar {
        token package-declarator:sym<test-hub> {
            <sym><.kok> <package-def('test-hub')>
            <.set_braid_from(self)>
        }
        token package-declarator:sym<test-bundle> {
            :my $*TEST-BUNDLE-TYPE;
            :my $*TEST-RESTORE-PACKAGE := True;
            <sym><.kok>
            { $*LANG.set_how('role', Test::Async::Metamodel::BundleHOW); }
            <package-def('role')>
            <.set_braid_from(self)>
        }
        token package-declarator:sym<test-reporter> {
            :my $*TEST-BUNDLE-TYPE;
            :my $*TEST-RESTORE-PACKAGE := True;
            <sym><.kok>
            { $*LANG.set_how('role', Test::Async::Metamodel::ReporterHOW); }
            <package-def('role')>
            <.set_braid_from(self)>
        }
        method set_package(|) {
            if $*TEST-RESTORE-PACKAGE {
                $*LANG.set_how('role', Metamodel::ParametricRoleHOW);
                $*TEST-RESTORE-PACKAGE := False;
            }
            nextsame
        }
    }

    my role TestAsyncActions {
        # `$<package-def>` in Raku-authored actions would compile to a Raku
        # postcircumfix on the bare grammar cursor, which has no candidate;
        # reach the capture through nqp instead.
        sub pkgdef(Mu $/) {
            nqp::atkey(nqp::findmethod($/, 'hash')($/), 'package-def')
        }

        method package-declarator:sym<test-hub>(Mu $/) {
            self.attach: $/, pkgdef($/).ast;
        }
        method package-declarator:sym<test-bundle>(Mu $/) {
            self.attach: $/, pkgdef($/).ast;
        }
        method package-declarator:sym<test-reporter>(Mu $/) {
            self.attach: $/, pkgdef($/).ast;
        }
    }

    # Everything in this block targets the legacy (pre-RakuAST) grammar and
    # can be removed once RakuAST is the only frontend: delete the two
    # `*-Legacy` roles and the legacy arm of the activation below.
    my role TestAsyncGrammar-Legacy {
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
        method set_package(|) {
            if $*TEST-RESTORE-PACKAGE {
                $*LANG.set_how('role', Metamodel::ParametricRoleHOW);
                $*TEST-RESTORE-PACKAGE := False;
            }
            nextsame
        }
    }

    my role TestAsyncActions-Legacy {
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

    # $*R, the RakuAST resolver, is present only while the RakuAST frontend
    # compiles. The legacy frontend has $*W instead.
    my $rakuast := $*R.defined;
    my \Grammar := $rakuast ?? TestAsyncGrammar         !! TestAsyncGrammar-Legacy;
    my \Actions := $rakuast ?? TestAsyncActions         !! TestAsyncActions-Legacy;
    unless $*LANG.^does(Grammar) {
        $*LANG.set_how('test-hub', Test::Async::Metamodel::HubHOW);
        $ = $*LANG.define_slang(
            'MAIN',
            $*LANG.HOW.mixin($*LANG.WHAT, Grammar),
            $*LANG.actions.^mixin(Actions)
        );
    }

    Map.new: ( EXPORT::DEFAULT:: )
}
