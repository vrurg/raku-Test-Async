use v6;

=begin pod
=NAME

C<Test::Async::Decl> - declarations for writing new bundles

=SYNOPSIS

    use Test::Async::Decl;

    unit test-bundle MyBundle;

    method my-tool(...) is test-tool(:name<mytool>, :!skippable, :!readify) {
        ...
    }

=DESCRIPTION

This module exports declarations needed to write custom bundles for C<Test::Async> framework.

=head2 C<test-bundle>

Declares a bundle role backed by
L<C<Test::Async::Metamodel::BundleHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleHOW.md>
metaclass.

=head2 C<test-reporter>

Declares a bundle role wishing to act as a reporter. Backed by
L<C<Test::Async::Metamodel::ReporterHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/ReporterHOW.md>
metaclass. The bundle also consumes
L<C<Test::Async::Reporter>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Reporter.md>
role.

=head2 C<test-hub>

This kind of package creates a hub class which is backed by
L<C<Test::Async::Metamodel::HubHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/HubHOW.md>
metaclass. Barely useful for a third-party developer.

=head2 C<&trait_mod:<is>(Method:D \meth, :$test-tool!)>

This trait is used to declare a method in a bundle as a test tool:

    method foo(...) is test-tool {
        ...
    }

The method is then exported to user as C<&foo> routine. Internally the method is getting wrapped into a code which
does necessary preparations for the tool to act as expected. See
L<C<Test::Async::Metamodel::BundleClassHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleClassHOW.md>
for more details.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Metamodel::BundleHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleHOW.md>,
L<C<Test::Async::Metamodel::BundleClassHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleClassHOW.md>,
L<C<Test::Async::Metamodel::HubHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/HubHOW.md>,
L<C<Test::Async::Metamodel::ReporterHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/ReporterHOW.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

use nqp;
use Test::Async::Metamodel::HubHOW;
use Test::Async::Metamodel::BundleHOW;
use Test::Async::Metamodel::ReporterHOW;
use Test::Async::TestTool;

multi trait_mod:<is>(Method:D \meth, :$test-tool!) is export {
    my %p = tool-name => meth.name, :readify, :skippable;
    if $test-tool ~~ Str:D {
        %p<tool-name> = $test-tool;
    }
    elsif $test-tool ~~ Positional | Iterable | Associative {
        my %tt = |$test-tool;
        for %tt.keys -> $param {
            if $param ~~ any(<name readify skip skippable>) {
                my $map-name = $param eq 'name' ?? 'tool-name' !! ($param eq 'skip' ?? 'skippable' !! $param);
                %p{$map-name} = %tt{$param};
            }
            else {
                die "Unknown tool-name trait parameter '$param'"
            }
        }
    }
    meth does Test::Async::TestTool;
    meth.set-tool-name(%p<tool-name>);
    meth.set-readify(%p<readify>);
    meth.set-skippable(%p<skippable>);
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
                self.set_how('role', Metamodel::ParametricRoleHOW);
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
