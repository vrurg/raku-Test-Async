use v6;
use nqp;
use Test::Async::Decl;
use Test::Async::Utils;

unit test-bundle Test::Async::Base;

use MONKEY-SEE-NO-EVAL;
use Test::Async::Event;

class Event::Cmd::SetTestFlunk is Event::Command { }

has Str:D $.FLUNK-message = "";
has Numeric:D $.FLUNK-count = 0;

method take-FLUNK {
    return Nil unless $!FLUNK-count;
    my $msg = $!FLUNK-message;
    $!FLUNK-message = "" unless --$!FLUNK-count;
    $msg
}

method pass(Str:D $message = "") is test-tool {
    self.proclaim: True, $message
}

method flunk(Str:D $message = "") is test-tool {
    self.proclaim: False, $message
}

method diag(+@msg) is test-tool(:!skip) {
    self.send: Event::Diag, :message(@msg.join);
}

method ok(Mu $cond, Str:D $message = "") is test-tool {
    self.proclaim: $cond, $message
}

method nok(Mu $cond, Str:D $message = "") is test-tool {
    self.proclaim: !$cond, $message
}

method isa-ok(Mu $got, Mu $expected, Str:D $message = "Is a '{$expected.^name}' type object") is test-tool {
    self.proclaim:
        test-result(
            $got.isa($expected),
            fail => {
                comments => self.expected-got($expected, $got)
            }),
        $message
}

method can-ok(Mu $got, Str:D $meth,
              Str:D $message = ($got.defined ?? 'An object of ' !! 'The type ')
                                ~ $got.^name ~ " can do the method '$meth'"
) is test-tool {
    self.proclaim: $got.^can($meth), $message
}

method does-ok(Mu $got, Mu \type-object,
               Str:D $message = ($got.defined ?? 'An object of ' !! 'The type ')
                                 ~ $got.^name ~ " does role " ~ type-object.^name
) is test-tool {
    self.proclaim: $got.^does(type-object), $message
}

proto method is(|) is test-tool {*}
multi method is(Mu $got, Mu:U $expected, $message = "") {
    my $result;
    my $got-str;
    if $got.defined {
        $result = False;
    }
    else {
        $result = nqp::if(
                    nqp::eqaddr($expected.WHAT, Mu),
                    nqp::eqaddr($got.WHAT, Mu),
                    nqp::if(
                        nqp::eqaddr($got.WHAT, Mu),
                        False,
                        $got === $expected));
    }
    self.proclaim:
            test-result($result,
                        fail => %(
                            comments => self.expected-got($expected, $got, :gist)
                        )),
            $message;
}
multi method is(Mu $got, Mu:D $expected, $message = "") {
    my $result;
    my ($exp-str, $got-str);
    if $got.defined {
        $result = nqp::if(
                    nqp::eqaddr($expected.WHAT, Mu),
                    nqp::eqaddr($got.WHAT, Mu),
                    nqp::if(
                        nqp::eqaddr($got.WHAT, Mu),
                        False,
                        ($got eq $expected)));
        unless $result {
            if try    $got     .Str.subst(/\s/, '', :g)
                   eq $expected.Str.subst(/\s/, '', :g)
            {
                # only white space differs, so better show it to the user
                $exp-str = $expected.raku;
                $got-str = $got.raku;
            }
            else {
                $exp-str = "'$expected'";
                $got-str = "'$got'";
            }
        }
    }
    else {
        $result = False;
        $exp-str = "'$expected'";
        $got-str = "({$got.^name})";
    }
    self.proclaim:
        test-result($result,
                    fail => %(
                        comments => self.expected-got($exp-str, $got-str)
                    )),
        $message;
}

proto method isnt(|) is test-tool {*}
multi method isnt(Mu $got, Mu:U $expected, $message = "") {
    my $result;
    if $got.defined {
        self.proclaim(True, $message);
        return;
    }
    $result = nqp::if(
                nqp::eqaddr($expected.WHAT, Mu),
                nqp::if(nqp::eqaddr($got.WHAT, Mu), False, True),
                nqp::if(
                    nqp::eqaddr($got.WHAT, Mu),
                    True,
                    $expected !=== $got));
    self.proclaim:
        test-result($result,
                    fail => %(
                        comments => self.expected-got($expected, $got, :quote)
                    )),
        $message;
}

multi method isnt(Mu $got, Mu:D $expected, $message = "") {
    my $result;
    unless $got.defined {
        self.proclaim(True, $message);
        return;
    }
    $result = $got ne $expected;
    self.proclaim:
        test-result($result,
                    fail => %(
                        comments => self.expected-got($expected, $got, :quote)
                    )),
        $message;
}

method cmp-ok(Mu $got is raw, $op, Mu $expected is raw, $message ='') is test-tool {
    my $result;
    my %ev-profile;
    # Defuse a Failure object
    $got.so if $got ~~ Failure;

    # the three labeled &CALLERS below are as follows:
    #  #1 handles ops that don't have '<' or '>'
    #  #2 handles ops that don't have '«' or '»'
    #  #3 handles all the rest by escaping '<' and '>' with backslashes.
    #     Note: #3 doesn't eliminate #1, as #3 fails with '<' operator
    my $matcher = nqp::istype($op, Callable) ?? $op
        !! &CALLERS::("infix:<$op>") #1
            // &CALLERS::("infix:«$op»") #2
            // &CALLERS::("infix:<$op.subst(/<?before <[<>]>>/, "\\", :g)>"); #3

    if $matcher {
        $result = test-result(
                    $matcher($got, $expected),
                    fail => %(
                        comments => self.expected-got($expected.raku, $got.raku)
                                    ~ "\n matcher: " ~ ($matcher.?name || $matcher.^name)
                    ));
    }
    else {
        $result =
            test-result(False,
                        fail => %(
                            comments =>
                                ("Could not use '$op.raku()' as a comparator."
                                ~ (' If you are trying to use a meta operator, pass it as a ',
                                   "Callable instead of a string: \&[$op]"
                                        unless nqp::istype($op, Callable)))
                        ));
    }
    self.proclaim: $result, $message;
}

method like(Str() $got, Regex:D $expected, Str $message = "text matches {$expected.raku}") is test-tool {
    self.proclaim:
        test-result(
            $got ~~ $expected,
            fail => {
                comments => self.expected-got($expected, $got, :exp-sfx('a match with'))
            }
        ),
        $message
}

method unlike(Str() $got, Regex:D $expected, Str $message = "text matches {$expected.raku}") is test-tool {
    self.proclaim:
        test-result(
            ! ($got ~~ $expected),
            fail => {
                comments => self.expected-got($expected, $got, :exp-sfx("no match with"))
            }
        ),
        $message
}

method use-ok(Str:D $code, Str:D $message = "'$code' can be use-d") is test-tool {
    try {
        EVAL "use $code";
    }
    self.proclaim:
        test-result(
            (! $!.defined),
            fail => {
                comments => ($! ?? ~$! !! Empty),
            }
        ),
        $message
}

method dies-ok(Callable $code, Str:D $message = "code anticipated to die") is test-tool {
    my $dies = True;
    try {
        $code();
        $dies = False;
    }

    self.proclaim: $dies, $message;
}

method lives-ok(Callable $code, Str:D $message = "code anticipated to die") is test-tool {
    my $lives = False;
    try {
        $code();
        $lives = True;
    }

    self.proclaim:
        test-result(
            $lives,
            fail => {
                comments => ($! ?? "Error: " ~ $! !! Empty),
            }
        ),
        $message;
}

method !eval-exception($code) {
    try { EVAL $code }
    $!
}

method eval-dies-ok(Str() $code, Str:D $message = "EVAL'ed code anticipated to die") is test-tool {
    my $ex = self!eval-exception($code);
    self.proclaim: $ex.defined, $message;
}

method eval-lives-ok(Str() $code, Str:D $message = "EVAL'ed code anticipated to die") is test-tool {
    my $ex = self!eval-exception($code);
    self.proclaim:
        test-result(
            !$ex.defined,
            fail => {
                comments => ($ex ?? "Error: " ~ $ex !! Empty),
            }
        ), $message;
}

method !validate-matchers(%matcher) {
    for %matcher.kv -> $k, $v {
        if $v.DEFINITE && $v ~~ Bool {
            X::Match::Bool.new(:type(".$k")).throw;
        }
    }
}

method throws-like($code where Callable:D | Str:D, $ex_type, Str:D $message = "did we throws-like $ex_type.^name()?", *%matcher) is test-tool {
    self!validate-matchers(%matcher);
    # Don't guess our caller context, know it!
    my $caller-context = $*TEST-THROWS-LIKE-CTX // CALLER::;
    my $rc = False;
    self.subtest: $message, :instant, {
        my \suite = self.test-suite;
        suite.plan: 2 + %matcher.keys.elems;
        my $msg;
        if $code ~~ Callable {
            $msg = 'code dies';
            $code()
        } else {
            $msg = "'$code' died";
            EVAL $code, context => $caller-context;
        }
        suite.flunk: $msg;
        suite.skip-rest: 'Code did not die, can not check exception'; #, 1 + %matcher.elems;
        CATCH {
            default {
                suite.pass: $msg;
                $rc = True;
                my $type_ok = $_ ~~ $ex_type;
                suite.ok: $type_ok, "right exception type ($ex_type.^name())";
                if $type_ok {
                    for %matcher.kv -> $k, $v {
                        my $got is default(Nil) = $_."$k"();
                        my $ok = $got ~~ $v;
                        $rc &&= $ok;
                        suite.proclaim:
                            test-result(
                                $ok,
                                fail => { comments => self.expected-got($v, $got), }
                            ),
                            ".$k matches $v.gist()"
                    }
                } else {
                    suite.send-test(
                        Event::Skip,
                        'wrong exception type',
                        TRSkipped,
                        comments => (self.expected-got($ex_type.^name, $_.^name),
                                     "Exception message: " ~ .message)
                    );
                    suite.skip-rest: 'wrong exception type';
                }
            }
        }
    };
    $rc
}

method fails-like (
    $code where Callable:D | Str:D, $ex-type, Str:D $message = "did we fails-like $ex-type.^name()?", *%matcher
) is test-tool {
    self!validate-matchers(%matcher);
    my $throws-like-context = $*TEST-THROWS-LIKE-CTX // CALLER::;
    my $rc = False;
    self.subtest: $message, :instant, {
        my \suite = self.test-suite;
        suite.plan: 2;
        CATCH { default {
            with "expected code to fail but it threw {.^name} instead" {
                suite.flunk: $_;
                suite.skip: $_;
            }
        }}
        my $res = $code ~~ Callable ?? $code() !! $code.EVAL;
        $rc = suite.isa-ok: $res, Failure, 'code returned a Failure';
        my $*TEST-THROWS-LIKE-CTX = $throws-like-context;
        $rc &&= suite.throws-like:
            { $res.sink },
            $ex-type,
            'Failure threw when sunk',
            |%matcher;
    };
    $rc
}

method is-approx-calculate(
    $got,
    $expected,
    $abs-tol where { !.defined or $_ >= 0 },
    $rel-tol where { !.defined or $_ >= 0 },
    Str:D $message = ""
) is test-tool
{
    my Bool    ($abs-tol-ok, $rel-tol-ok) = True, True;
    my Numeric ($abs-tol-got, $rel-tol-got);
    if $abs-tol.defined {
        $abs-tol-got = abs($got - $expected);
        $abs-tol-ok = $abs-tol-got <= $abs-tol;
    }
    if $rel-tol.defined {
        if max($got.abs, $expected.abs) -> $max {
            $rel-tol-got = abs($got - $expected) / $max;
            $rel-tol-ok = $rel-tol-got <= $rel-tol;
        }
        else {
            # if $max is zero, then both $got and $expected are zero
            # and so our relative difference is also zero
            $rel-tol-got = 0;
        }
    }

    my $result = test-result(
                    $abs-tol-ok && $rel-tol-ok,
                    fail => %(
                        "comments" => (
                              "    expected approximately: $expected\n"
                            ~ "                       got: $got",
                            $abs-tol-ok
                            ?? Empty
                            !!   "maximum absolute tolerance: $abs-tol\n"
                               ~ "actual absolute difference: $abs-tol-got",
                            $rel-tol-ok
                            ?? Empty
                            !!   "maximum relative tolerance: $rel-tol\n"
                               ~ "actual relative difference: $rel-tol-got"
                        ),
                    )
    );
    # note "RESULT? ", $result.fail-profile.raku;
    self.proclaim($result, $message);
}

# We're picking and choosing which tolerance to use here, to make it easier
# to test numbers close to zero, yet maintain relative tolerance elsewhere.
# For example, relative tolerance works equally well with regular and huge,
# but once we go down to zero, things break down: is-approx sin(τ), 0; would
# fail, because the computed relative tolerance is 1. For such cases, absolute
# tolerance is better suited, so we DWIM in the no-tol version of the sub.
proto method is-approx(|) is test-tool {*}
multi method is-approx(Numeric $got, Numeric $expected, $desc = '') is export {
    $expected.abs < 1e-6
        ?? self.is-approx-calculate($got, $expected, 1e-5, Nil, $desc) # abs-tol
        !! self.is-approx-calculate($got, $expected, Nil, 1e-6, $desc) # rel-tol
}

multi method is-approx(
    Numeric $got, Numeric $expected, Numeric $abs-tol, $desc = ''
) {
    self.is-approx-calculate($got, $expected, $abs-tol, Nil, $desc);
}

multi method is-approx(
    Numeric $got, Numeric $expected, $desc = '',
    Numeric :$rel-tol is required, Numeric :$abs-tol is required
) {
    self.is-approx-calculate($got, $expected, $abs-tol, $rel-tol, $desc);
}

multi method is-approx(
    Numeric $got, Numeric $expected, $desc = '', Numeric :$rel-tol is required
) {
    self.is-approx-calculate($got, $expected, Nil, $rel-tol, $desc);
}

multi method is-approx(
    Numeric $got, Numeric $expected, $desc = '', Numeric :$abs-tol is required
) {
    self.is-approx-calculate($got, $expected, $abs-tol, Nil, $desc);
}

proto method is-deeply(|) is test-tool {*}
multi method is-deeply(Seq:D $got, Seq:D $expected, $message = '') {
    self.is-deeply: $got.cache, $expected.cache, $message;
}
multi method is-deeply(Seq:D $got, Mu $expected, $message = '') {
    self.is-deeply: $got.cache, $expected, $message;
}
multi method is-deeply(Mu $got, Seq:D $expected, $message = '') {
    self.is-deeply: $got, $expected.cache, $message;
}
multi method is-deeply(Mu $got, Mu $expected, $message = '') {
    my $result = test-result
                    $got eqv $expected,
                    fail => %(
                        comments => self.expected-got($expected, $got),
                    );
    self.proclaim($result, $message)
}

method skip(Str:D $message = "", UInt:D $count = 1) is test-tool {
    for ^$count {
        self.send-test: Event::Skip, $message, TRSkipped
    }
}

method skip-rest(Str:D $message = "") is test-tool {
    if self.planned.defined {
        self.skip($message, self.planned);
    }
    else {
        self.throw: X::PlanRequired, :op<skip-rest>
    }
}

method skip-remaining(Str:D $message = "", Bool :$global?) is test-tool {
    self.send-command: Event::Cmd::SkipRemaining, $message;
    if $global {
        .skip-remaining: $message, :$global with $.parent-suite;
    }
    # Make sure no other test tool is ran in our thread until skipping gets into effect.
    self.sync-events;
}

method todo(Str:D $message, UInt:D $count = 1) is test-tool {
    self.set-todo($message, $count);
    self.sync-events;
}

method todo-remaining(Str:D $message) is test-tool {
    self.set-todo($message, Inf);
    self.sync-events;
}

method bail-out(Str:D $message = "") is test-tool {
    self.send: Event::BailOut, :$message;
    self.sync-events;
    exit 255;
}

proto method subtest(|) is test-tool {*}
multi method subtest(Pair:D $subtest (Str(Any:D) :key($message), :value(&code)), *%plan) is hidden-from-backtrace {
    self.subtest(&code, $message, |%plan);
}
multi method subtest(Str:D $message, Callable:D \subtests, *%plan) is hidden-from-backtrace {
    self.subtest(subtests, $message, |%plan)
}
multi method subtest(Callable:D \subtests, Str:D $message, Bool:D :$instant = False, *%plan) is hidden-from-backtrace
{
    my $jobh = self.claim-job;
    my %profile = :code(subtests), :$message;
    my $caller = $*TEST-CALLER;
    my $child = self.create-child: |%profile;
    $child.plan: %plan if %plan;
    self.invoke-child( $child, :$instant ).then: {
        CATCH {
            default {
                note "===SORRY!=== .then block died in subtest with ", $_.^name,
                     "called at ", $caller;
                exit 1;
            }
        }
        my %ev-profile = :$caller;
        if $child.is-TODO {
            %ev-profile<todo> = $child.TODO-message;
        }
        if $child.messages.elems {
            %ev-profile<child-messages> := $child.messages<>;
        }
        self.proclaim:
                (!$child.tests-failed && (!$child.planned || $child.planned == $child.tests-run)),
                $message,
                %ev-profile;
        self.release-job($jobh);
    }
}

proto method is-run(|) is test-tool {*}
multi method is-run(Str() $code, %expected, Str $message = "") {
    self.is-run: $code, $message, |%expected
}
multi method is-run (
    Str() $code, $message = "",
    Stringy :$in, :@compiler-args, :@args, :$out?, :$err?, :$exitcode = 0
) {
    my @proc-args = flat do if $*DISTRO.is-win {
        # $*EXECUTABLE is a batch file on Windows, that goes through cmd.exe
        # and chokes on standard quoting. We also need to remove any newlines
        <cmd.exe  /S /C>, $*EXECUTABLE, @compiler-args, '-e',
        ($code,  @args).subst(:g, "\n", " ")
    }
    else {
        $*EXECUTABLE, @compiler-args, '-e', $code, @args
    }

    with run :in, :out, :err, @proc-args {
        $in ~~ Blob ?? .in.write: $in !! .in.print: $in if $in;
        $ = .in.close;
        my $proc-out      = .out.slurp: :close;
        my $proc-err      = .err.slurp: :close;
        my $proc-exitcode = .exitcode;

        my $wanted-exitcode = $exitcode // 0;

        self.subtest: $message, :instant, {
            given self.test-suite {
                .plan(1 + ?$out.defined + ?$err.defined);
                .cmp-ok: $proc-out,      '~~', $out,             'STDOUT' if $out.defined;
                .cmp-ok: $proc-err,      '~~', $err,             'STDERR' if $err.defined;
                .cmp-ok: $proc-exitcode, '~~', $wanted-exitcode, 'Exit code';
            }
        }
    }
}

method cmd-settestflunk(Str:D $message, Numeric:D $count) {
    $!FLUNK-message = $message;
    $!FLUNK-count = $count;
}

method !set-FLUNK($message, $count) {
    self.send-command: Event::Cmd::SetTestFlunk, $message, $count;
    self.sync-events;
}

my constant TEST-FLUNK-MSG = 'anticipated test failure';
proto method test-flunks(|) is test-tool(:!skippable) {*}
multi method test-flunks(Str:D $message = TEST-FLUNK-MSG, :$remaining! where *.so) {
    self!set-FLUNK(TEST-FLUNK-MSG, Inf)
}
multi method test-flunks(Inf) {
    self!set-FLUNK(TEST-FLUNK-MSG, Inf)
}
multi method test-flunks(Int:D $count where * > 0 = 1) {
    self!set-FLUNK(TEST-FLUNK-MSG, $count)
}
multi method test-flunks(Str:D $message, Inf) {
    self!set-FLUNK($message, Inf)
}
multi method test-flunks(Str:D $message = TEST-FLUNK-MSG, Int:D $count where * > 0 = 1) {
    self!set-FLUNK($message, $count)
}

proto method expected-got(Mu, Mu, |) {*}
multi method expected-got(Str:D $expected, Str:D $got, Str :$exp-sfx, Str :$got-sfx) {
    my $exp-str = "expected" ~ ($exp-sfx ?? " $exp-sfx" !! "");
    my $got-str = "got" ~ ($got-sfx ?? " $got-sfx" !! "");
    my $flen = max $exp-str.chars, $got-str.chars;
    my $format = "%" ~ $flen ~ "s: ";
      $exp-str.fmt($format) ~ $expected ~ "\n"
    ~ $got-str.fmt($format) ~ $got
}
multi method expected-got(+@pos where *.elems == 2, :$gist?, :$quote?, *%c) {
    my @stringified;
    for @pos -> $pos {
        my $spos;
        if $gist && nqp::can($pos, 'gist') {
            $spos = try $pos.gist;
        }
        unless $spos {
            $spos = stringify($pos);
            $spos = "'$spos'" if $quote;
        }
        @stringified.push: $spos;
    }
    self.expected-got: |@stringified, |%c;
}

# Wrap the default method to invert test result when test-flunks is in effect.
multi method send-test(::?CLASS:D: Event::Test:U \evType, Str:D $message, TestResult:D $tr, *%profile) {
    if (my $fmsg = self.take-FLUNK).defined {
        my sub fail-message($reason) {
              "NOT FLUNK: $fmsg\n"
            ~ "    Cause: Test $reason"
        }
        my $evType := evType;
        my $test-result;
        my @comments = %profile<comments> || [];
        given evType {
            when Event::NotOk {
                @comments.unshift: 'FLUNK - ' ~ $fmsg;
                $evType := Event::Ok;
                $test-result = TRPassed;
            }
            when Event::Ok {
                @comments.unshift: fail-message('passed');
                $evType := Event::NotOk;
                $test-result = TRFailed;
            }
            # skips are ok to ignore
            when Event::Skip { $test-result = $tr; }
            # This would catch any custom event from a 3rd party bundle.
            default {
                @comments.unshift: fail-message('resulted in unknown ' ~ evType.^name ~ " event");
                $evType := Event::NotOk;
                $test-result = TRFailed;
            }
        }
        callwith( $evType, $message, $test-result, |%profile, :@comments );
    }
    else {
        callsame
    }
    # say "RETURN($message):", $tr == TRPassed;
    $tr == TRPassed
}
multi method send-test(::?CLASS:D: |) { nextsame }
