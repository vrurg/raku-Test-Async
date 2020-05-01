use v6;

=begin pod
=NAME

C<Test::Async::Reporter> - a reporter bundle role

=DESCRIPTION

This role is applied to a bundle declared with C<test-reporter>. Implies implementations of methods:

=item C<report-event(Event:D)> – report an event to user
=item C<indent-message(+@message, :$prefix, :$nesting, *% --> Array())> - indent all lines in C<@message> using
C<$prefix> by C<$nesting> levels. C<@message> is expected to be in normalized form (see
C<normalize-message> in L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.9/docs/md/Test/Async/Hub.md>).
=item C<message-to-console(+@message)> – send C<@message> to its final destination.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.9/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.9/docs/md/Test/Async/Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit role Test::Async::Reporter;
use Test::Async::Event;

method report-event(Event:D) {...}
method indent-message(+@message, :$prefix, :$nesting, *% --> Array()) {...}
method message-to-console(+@message) {...}
