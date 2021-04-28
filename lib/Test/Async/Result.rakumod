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

Profiles to be used to create a new C<Event::Test> object. Depending on C<$.cond> value either C<success-> or
C<fail-profile> is used. The most typical use of this is to add comments explaining the test outcome.

A profile attribute can be made lazy if assigned with a code object:

    my $tr = test-result($condition, fail => -> { comments => self.expected-got($expected, $got) });

In this case C<event-profile> method will invoke the code and use the return value as profile itself. This improves
performance in cases when profile keys are set using some rather heavy code (like the C<expected-got> method in the
example above) but eventually might not even be used after all.

=METHODS

=head2 C<event-profile(--> Capture:D)>

Returns a profile accordingly to C<$.cond>.

The profile capture is built the following way:

=item if corresponding profile attribute is code then the code is invoked and return value is used
=item profile is coerced into a hash
=item all hash values are deconted
=item the result is coerced into L<C<Capture>|https://docs.raku.org/type/Capture>

Deconting of the values is done to solve some cases of improper initialization of C<Event> attributes.

=head1 SEE ALSO

C<test-result> routine from L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.900/docs/md/Test/Async/Utils.md>.

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod
# Test result object.
unit class Test::Async::Result;

# ok/not ok test
has Bool:D $.cond is required;
has $.fail-profile;
has $.success-profile;

method event-profile(--> Capture:D) {
    my $profile = ($!cond ?? $!success-profile !! $!fail-profile) // ();
    %($profile ~~ Code ?? $profile.() !! $profile)
        .map({ .key => .value<> })
        .Capture
}
