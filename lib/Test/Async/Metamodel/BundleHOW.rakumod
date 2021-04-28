use v6;

=begin pod
=NAME

C<Test::Async::Metamodel::BundleHOW> - metaclass backing bundle roles

=DESCRIPTION

The only function is to register the bundle role with slang defined in
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.0/docs/md/Test/Async/Decl.md>.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.0/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.0/docs/md/Test/Async/Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit class Test::Async::Metamodel::BundleHOW is Metamodel::ParametricRoleHOW;
use Test::Async::Metamodel::HubHOW;

method new_type(|) {
    $*TEST-BUNDLE-TYPE := callsame;
    unless $*W && $*W.is_precompilation_mode {
        Test::Async::Metamodel::HubHOW.register-bundle: $*TEST-BUNDLE-TYPE;
    }
    $*TEST-BUNDLE-TYPE
}
