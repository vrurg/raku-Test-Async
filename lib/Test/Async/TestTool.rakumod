use v6;

=begin pod
=NAME

C<Test::Async::TestTool> - role consumed by test tool methods

=DESCRIPTION

This role is applied by C<test-tool> trait to a test tool method.

=ATTRIBUTES

=head2 C<$.tool-name>

Contains the name which must be used for exporting a test tool routine. Makes sense if method must be named differently
from what is provided for the user.

=head2 L<C<Bool:D>|https://docs.raku.org/type/Bool> C<$.readify>

This flag is indicating if test tool must cause it's suite object to transition from C<TSInitializing> stage.

=head2 L<C<Bool:D>|https://docs.raku.org/type/Bool> C<$.skippable>

This flag indicates that this test tool could be skipped. A typical example of a non-skippable tool is the C<skip>
itself, or C<todo> tool family. The importance of this nuance stems from the fact that when C<skip-remaining> tool is in
effect the wrapper of a test tool code detects this situation and emits a skip event instantly without actually invoking
the tool method. Without C<$.skippable> reset to I<False> a line like:

    skip "for a reason", 3;

would result in a single skip event which is counted as a test run. Our plan will fail because of 2 missing skip events.

=head2 L<C<Bool:D>|https://docs.raku.org/type/Bool> C<$.wrappable>

Resetting this flag to I<False> would result in test tool method would be left intact by
L<C<Test::Async::Metamodel::BundleClassHOW>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Metamodel/BundleClassHOW.md>.

=head2 L<C<Bool:D>|https://docs.raku.org/type/Bool> C<$.anchoring>

Marks a test tool as an I<anchoring> one. See
L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Manual.md>
Call Location And Anchoring section for more details.

I<False> by default.

=METHODS

=head2 C<set-tool-name(Str:D $name)>

Sets C<$.tool-name>.

=head2 C<set-readify(Boold:D $readify)>

Sets C<$.readify>

=head2 C<set-skippable(Bool:D $skippable)>

Sets C<$.skippable>

=head2 C<set-wrappable(Bool:D $wrappable)>

Sets C<$.wrappable>

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit role Test::Async::TestTool;
has $.tool-name;
has Bool:D $.readify = True;
has Bool:D $.skippable = True;
has Bool:D $.wrappable = True;
has Bool:D $.anchoring = False;

method set-tool-name(Str:D $!tool-name)    { }
method set-readify(Bool:D $!readify)       { }
method set-skippable(Bool:D $!skippable)   { }
method set-wrappable(Bool:D $!wrappable)   { }
method set-anchoring(Bool:D $!anchoring)   { }
