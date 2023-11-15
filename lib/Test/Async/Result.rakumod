use v6;

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
