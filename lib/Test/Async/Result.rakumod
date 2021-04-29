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

A profile attribute can be made lazy if set to a code object:

    my $tr = test-result($condition, fail => -> { comments => self.expected-got($expected, $got) });

In this case C<event-profile> method will invoke the code and use the return value as profile itself. This improves
performance in cases when profile keys are set using some rather heavy code (like the C<expected-got> method in the
example above) but eventually might not even be used after all.

=METHODS

=head2 C<event-profile(--> Hash:D)>

Returns a profile in accordance to C<$.cond> value.

The profile capture is built the following way:

=item if corresponding profile attribute is code then the code is invoked and return value is used
=item profile is coerced into a hash

=head1 SEE ALSO

C<test-result> routine from
L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Utils.md>.

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod
# Test result object.
unit class Test::Async::Result;

# ok/not ok test
has Bool:D $.cond is required;
has $.fail-profile;
has $.success-profile;

method event-profile(::?CLASS:D: --> Hash:D) {
    my $profile = ($!cond ?? $!success-profile !! $!fail-profile) // ();
    %($profile ~~ Code ?? $profile.() !! $profile).Hash
}
