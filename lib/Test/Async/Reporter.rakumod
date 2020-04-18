use v6;

=begin pod
=NAME

C<Test::Async::Reporter> - a reporter bundle role

=DESCRIPTION

This role is applied to a bundle declared with C<test-reporter>.

=head1 SEE ALSO

L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit role Test::Async::Reporter;
use Test::Async::Event;

method report-event(Event:D) {...}
method indent-message(+@message, :$prefix, :$nesting, *% --> Array()) {...}
