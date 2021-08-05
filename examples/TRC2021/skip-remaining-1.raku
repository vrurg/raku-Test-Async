use v6;
use Test::Async;

# A test case where we don't know the number of tests beforehand.

my $fail = False;
my $failed = False;

for ^Inf -> $n {
    $fail = rand < 0.3 unless $fail || $failed;
    subtest "Demo $n" => {
        die "double fail!" if $failed;
        ok !$fail, "test is ok"; 
    }
    if $fail && !$failed {
        skip-remaining "doesn't make sense after a failure";
        $fail = False;
        $failed = True;
    }
    last if ($failed && rand > 0.9) || ($n > 10);
}
