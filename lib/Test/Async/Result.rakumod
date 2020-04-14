use v6;
# Test result object.
unit class Test::Async::Result;

# ok/not ok test
has Bool:D $.cond is required;
has Capture $.fail-profile;
has Capture $.success-profile;

method event-profile {
    ($!cond ?? $!success-profile !! $!fail-profile) // \();
}
