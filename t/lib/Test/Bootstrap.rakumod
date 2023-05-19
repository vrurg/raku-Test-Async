use v6.e.PREVIEW;
unit module Test::Bootstrap;

my $planned;
my $test-id = 0;
my $test-failed = 0;

sub plan(Int:D $count) is export {
    $planned = $count;
    say "1..$count";
}

sub pass(Str:D $message) is export {
    say "ok {++$test-id} - ", $message;
}

sub flunk(Str:D $message) is export {
    ++$test-failed;
    say "not ok {++$test-id} - ", $message;
}

sub ok(Bool(Mu) $ok, Str:D $message = "") is export {
    if $ok {
        pass $message;
    }
    else {
        flunk $message;
    }
}

sub diag(Str:D $message) is export {
    say $message.split("\n").map('# ' ~ *).join("\n");
}

sub done-testing is export {
    if $test-failed {
        diag "You failed $test-failed test{$test-failed == 1 ?? '' !! 's'}" ~ (" of $planned" if $planned);
    }
    if $planned.defined && $test-id != $planned {
        diag "You planned $planned tests but ran $test-id";
    }
    unless $planned.defined {
        say "1..$test-id";
    }
}

sub like(Str:D $got, Regex:D $expect, $message) is export {
    if $got ~~ /:s^$expect/ {
        ok True, $message;
        return;
    }
    flunk $message;
    diag "expected: '$expect'";
    diag "     got: {$got.defined ?? "<<$got>>" !! "*undef*"}";
}

sub is-run(Str:D $code, Str:D $message = "$code runs",
           :@compiler-args, :$out = '', :$err = '', :$exitcode = 0,
           :$timeout) is export
{
    my $ok = True;
    my @msg;
    with run($*EXECUTABLE, @compiler-args, :in, :out, :err) {
        .in.print: $code;
        $ = .in.close;
        my $proc-exitcode;
        my Bool $in-time;
        if $timeout {
            await Promise.anyof( Promise.in($timeout).then({ cas($in-time, Bool, False) }),
                                 start {
                                     $proc-exitcode = .exitcode;
                                     cas($in-time, Bool, True);
                                 });
        }
        else {
            $proc-exitcode = .exitcode;
            $in-time = True;
        }
        if $in-time {
            if $proc-exitcode != $exitcode {
                $ok = False;
                @msg.push: "Expected exitcode $exitcode but got " ~ .exitcode;
            }
            unless ( my $pout = .out.slurp(:close) ) ~~ $out {
                $ok = False;
                @msg.push: "Standard output doesn't match.\n"
                           ~ "expected: { $out.raku }\n"
                           ~ "     got: { $pout.raku }";
            }
            # note "<<<<<<<<<<<<<\n", $pout, "\n>>>>>>>>>>>>>>>>";
            unless ( my $perr = .err.slurp(:close) ) ~~ $err {
                $ok = False;
                @msg.push: "Standard error doesn't match.\n"
                           ~ "expected: { $err.raku }\n"
                           ~ "     got: { $perr.raku }";
            }
        }
        else {
            $ok = False;
            @msg.push: "Process timed out in " ~ $timeout ~ " sec.";
        }
    }
    ok $ok, $message;
    diag @msg.join("\n") if @msg;
}
