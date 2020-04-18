use v6;

=begin pod
=NAME

C<Test::Async::Result> - test result representation

=SYNOPSIS

    self.proclaim: test-result(
                        $condition, 
                        fail => {
                            comments => "a comment about the cause of flunk",
                        });

=DESCRIPTION

This class represents information about test outcomes.

=ATTRIBUTES

=head2 C<Bool:D $.cond>

I<True> if test is considered success, I<False> otherwise. B<Note> that a skipped tests is a success.

=head2 C<$.fail-profile>, C<$.success-profile>

Profile to be used to create a new C<Event::Test> object depending on C<$.cond> value either C<success-> or
C<fail-profile> is used. The most typical use of this is to add comments explaining the test outcome.

=METHODS

=head2 C<event-profile()>

Returns a profile accordingly to C<$.cond>.

=head1 SEE ALSO

C<test-result> routine from L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Utils.md>.

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod
# Test result object.
unit class Test::Async::Result;

# ok/not ok test
has Bool:D $.cond is required;
has Capture $.fail-profile;
has Capture $.success-profile;

method event-profile {
    ($!cond ?? $!success-profile !! $!fail-profile) // \();
}
