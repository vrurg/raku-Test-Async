use v6;

=begin pod
=NAME 

C<Test::Async::Metamodel::ReporterHOW> - metaclass backing a reporter bundle

=DESCRIPTION

This class inherits from C<Test::Async::Metamodel::BundleHOW> and adds implicit application of
L<C<Test::Async::Reporter>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.12/docs/md/Test/Async/Reporter.md>
role.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.12/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.12/docs/md/Test/Async/Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit class Test::Async::Metamodel::ReporterHOW;

use Test::Async::Metamodel::BundleHOW;
use Test::Async::Reporter;

also is Test::Async::Metamodel::BundleHOW;

method new_type(|) {
    my \reporter-typeobj = callsame;
    reporter-typeobj.^add_role(Test::Async::Reporter);
    reporter-typeobj
}
