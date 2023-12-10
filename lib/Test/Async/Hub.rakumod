use v6;


use Test::Async::Decl;

unit test-hub Test::Async::Hub;

my class AbortSuite does X::Control { }

use Test::Async::Aggregator;
use Test::Async::JobMgr;
use Test::Async::Utils;
use Test::Async::Event;
use Test::Async::TestTool;
use Test::Async::Result;
use Test::Async::X;

also does Test::Async::Aggregator;
also does Test::Async::JobMgr;

has ::?CLASS $.parent-suite;

my atomicint $next-id = 0;
has Int:D $.id = $next-id⚛++;

# Message associated with this suite. Only makes sense for children.
has Str $.message = "TOP SUITE " ~ $*PROGRAM-NAME;
# Test code block we will invoke.
has &.code;

# This is what we start with.
has TestStage:D $!stage = TSInitializing;
has Promise:D $.completed .= new;
has $!completed-vow = $!completed.vow;
has Int $.planned;
# A message set with skip-rest
has Str $.skip-message;
has Str:D $.TODO-message = "";
has Numeric:D $.TODO-count where Inf | Int:D = 0;
# How far away our hub from the top one?
has Int:D $.nesting = 0;
has Str:D $.nesting-prefix = "  ";
# If true the suite will report it's parent tool-caller attribute.
has Bool:D $.transparent = False;
has ToolCallerCtx $.suite-caller where *.defined;

# Are we an asynchronous child? Transitive, i.e. event if the suit is started synchronously by a parent but the parent
# itself is async – this becomes true.
has Bool:D $.is-async = False;
# If the suite is TODOed by parent then this would be set to TODO message.
has Str $.is-TODO;
# Run children in random order.
has Bool $.random;

has atomicint $!next-test-id = 1;
has atomicint $.tests-run = 0;
has atomicint $.tests-failed = 0;
# &*EXIT handler prior to suite's user code invocation
has &!EXIT;
has Int $!exit-code;

# Run children in individual threads
has Bool $.parallel;
# Messages collected during test code run.
has Str:D @.messages;
# How many jobs can be invoked in parallel.
has UInt:D $.test-jobs = ((%*ENV<TEST_JOBS> andthen .Int) || ($*KERNEL.cpu-cores - 2)) max 1;
has $.job-timeout where Int:D | Inf = (%*ENV<TEST_ASYNC_JOB_TIMEOUT> || Inf).Num;

# Debug attributes
has Bool $.trace-mode is rw = ? %*ENV<TEST_ASYNC_TRACING>;  # Tracing writes into output-<id>.trace file

has Thread $!thread;

method new(|c) {
    # This class is already mutated into a suit
    self === ::?CLASS
        ?? self.^construct-suite.new(|c)
        !! nextsame
}

submethod TWEAK(|) {
    with $!parent-suite {
        $!suite-caller = $_ with .tool-caller;
        $!trace-mode = .trace-mode;
        $!transparent ||= .transparent;
    }
    else {
        $!suite-caller = self.locate-tool-caller(2);
    }
    if $!transparent {
        with $!parent-suite {
            # If a hidden subtest invoked directly under its parent subtest then the tool stack is empty and the tool
            # which created us is the parent suite itself.
            $!suite-caller = .tool-caller // .suite-caller;
        }
        else {
            self.throw: Test::Async::X::TransparentWithoutParent
        }
    }
    self.start-event-loop;
}

my $singleton;
method top-suite {
    # Tool call stack
    cas $singleton, {
        PROCESS::<@TEST-TOOL-STACK> = [] unless .defined;
        $_ // self.new
    }
}

method has-top-suite {
    $singleton.defined
}

method test-suite {
    $*TEST-SUITE // self.top-suite
}

# The first invocation of this method will record the current thread choosing it as suit's primary
method thread {
    $!thread //= $*THREAD
}

my @stage-equivalence = TSInitializing, TSInProgress, TSInProgress, TSFinished, TSDismissed, TSDismissed;

method stage { $!stage }

method set-stage(TestStage:D $stage, :%params = {}) {
    return $!stage if $!stage == $stage;
    loop {
        my $cur-stage = $!stage;
        # Prevent possible race condition when two concurrent locations are trying to set different states.
        # States are defined by the equivalence table.
        self.throw: Test::Async::X::StageTransition, :from($cur-stage), :to($stage)
            if @stage-equivalence[$cur-stage] > @stage-equivalence[$stage];
        # Do nothing if requested stage is equivalent to the current one but precedes it.
        return $cur-stage if $cur-stage > $stage;
        if cas($!stage, $cur-stage, $stage) == $cur-stage {
            # Don't panic if the event queue is non-functional.
            self.try-send: Event::StageTransition, :from($cur-stage), :to($stage), :%params;
            return $cur-stage;
        }
    }
}

multi method event(::?CLASS:D: Event::Command:D $ev) {
    my $cmd-name = $ev.^name
                    .split( '::' )
                    .grep({ "Event" ^ff * })
                    .map( *.lc )
                    .join( '-' );
    self."$cmd-name"(|$ev.args);
}
multi method event(::?CLASS:D: Event::Report:D $ev) {
    self.report-event($ev);
    nextsame
}

method setup-from-plan(%plan) {
    my $cur-stage = %plan<tests>:exists ?? $.set-stage(TSInProgress) !! $!stage;
    if $cur-stage != TSInitializing {
        self.throw: Test::Async::X::PlanTooLate;
    }
    if %plan<tests> {
        $!planned = %plan<tests>:delete;
    }
    if %plan<skip-all> {
        $!skip-message = %plan<skip-all>:delete;
    }
    if %plan<todo> {
        $!TODO-message = %plan<todo>:delete;
        $!TODO-count = Inf;
    }
    $!test-jobs = $_ with %plan<test-jobs>:delete;
    $!job-timeout = $_ with %plan<job-timeout>:delete;
    $!parallel = .so with %plan<parallel>:delete;
    $!random = .so with %plan<random>:delete;
}

proto method plan(|) is test-tool(:!skippable, :!readify) {*}
multi method plan(UInt:D $tests, *%plan) {
    %plan<tests> //= $tests;
    self.plan: |%plan;
}
multi method plan(*%plan) {
    CATCH {
        when Test::Async::X::PlanTooLate {
            self.send: Event::Diag, :message("FAILURE: " ~ .message);
            $!tests-failed = $!planned // 1;
            if self.parent-suite {
                self.abort;
            }
            else {
                self.finish;
            }
        }
        default { .rethrow }
    }
    self.setup-from-plan: %plan;
    if $!planned {
        self.send-plan($!planned, :on-start);
    }
    if %plan {
        self.send: Event::Diag, :message("Unknown plan parameter: " ~ $_) for %plan.keys;
    }
}

method exit-code {
    $!exit-code
    || ($!tests-failed min 254)
    || ($!planned.defined && ($!planned != ($!tests-run // 0))
        ?? 255
        !! 0)
}

method done-testing() is test-tool(:!skippable) {
    self.finish;
}

method abort-testing() is test-tool(:!skippable) {
    self.finish;
    if $!nesting {
        # A child suite can be aborted
        self.abort;
    }
    else {
        # The top suite must gracefully exit to shell
        exit self.exit-code;
    }
}

method cmd-skipremaining(Str:D $message) {
    $!skip-message = $message;
}

method cmd-syncevents($vow) {
    # self.trace-out: "SYNCING EVENTS ON VOW ", $vow.WHICH;
    $vow.keep(True);
}

# Accepts normalized message
method cmd-message(+@message) {
    # self.trace-out: "Collecting a message: ", @message.raku;
    @!messages.append: @message;
    # self.trace-out: "! Message collected !";
}

method cmd-settodo(Str:D $!TODO-message, Numeric:D $!TODO-count) { }

method cmd-bailout(Int:D $exit-code) {
    # note "@@@ BAILING OUT WITH rc==", $exit-code;
    exit $exit-code // $!exit-code // 255;
}

method create-suite(::?CLASS:D: ::?CLASS:U \suiteType = self.WHAT, *%c) {
    my %profile = :parent-suite(self), :nesting($!nesting + 1), :$!random,
                  :$!transparent;
    with self.take-TODO {
        # If a subtest falls under a todo then all its tests are todo
        %profile<is-TODO> = $_;
    }
    suiteType.new: |%profile, |%c
}

method invoke-suite(::?CLASS:D $suite, Bool:D :$async = False, Bool:D :$instant = False, Capture:D :$args = \()) {
    my $is-async = $async || ($!parallel && !$instant);
    my $job = self.new-job: {
        $suite.run(:$is-async, :$args)
    }, :$async;
    # self.trace-out: "SUITE #", $suite.id, " «", $suite.message, "» JOB ID: ", $job.id;
    if $!random && $!stage == TSInProgress && !$instant {
        self.postpone: $job;
    }
    elsif $is-async {
        self.start-job: $job;
    }
    else {
        self.invoke-job: $job;
    }
    $suite.completed
}

method run(:$is-async, Capture:D :$args = \()) {
    # If any parent is async all its children are async too.
    # self.trace-out: "Run suite ", $.id.fmt('%5d'), " «", $.message, "»";
    CONTROL {
        when AbortSuite {
            self.dismiss;
            return
        }
        default { .rethrow }
    }
    CATCH {
        default {
            # Report failure by having at least one failed test.
            with $!planned {
                $!tests-failed += $!planned - $!tests-run;
            }
            self.fatality(exception => $_)
        }
    }
    $!is-async = ($!parent-suite && $!parent-suite.is-async) || ?$is-async;
    my $*TEST-SUITE = self;
    &!EXIT = &*EXIT;
    LEAVE &!EXIT = Nil;
    {
        my &*EXIT = sub TEST-ASYNC-EXIT($status) {
            self.proclaim: False, "exit() used within a test suite";
            &*EXIT = &!EXIT;
            self.finish(:now);
            self.fatality($status);
        }
        &!code(|$args);
    }
    self.finish;
}

method throw(Test::Async::X::Base:U \exType, *%c) is hidden-from-backtrace {
    exType.new( :suite(self), |%c ).throw
}

method abort { AbortSuite.new.throw }

method send-command(Event::Command:U \evType, |c) {
    self.send: evType, :args(c)
}

proto method send-test(::?CLASS:D: Event::Test, |) {*}
multi method send-test(::?CLASS:D: Event::Test:U \evType, Str:D $message, TestResult:D $tr, *%c --> Bool:D) {
    self.send-test(evType, $message, $tr, %c)
}
multi method send-test(::?CLASS:D: Event::Test:U \evType,
                       Str:D $message,
                       TestResult:D $tr,
                       %ev-profile,
                       Bool :$bypass-todo,
                       --> Bool:D)
{
    my %profile;
    ++⚛$!tests-run;
    unless $bypass-todo {
        %profile<todo> = $_ with self.take-TODO;
    }
    if $tr == TRFailed && !(%profile<todo> || %ev-profile<todo>) {
        ++⚛$!tests-failed;
    }
    %profile<caller> = self.tool-caller // $.suite-caller
        unless %ev-profile<caller>;
    self.send: evType, :$message, |%profile, |%ev-profile;
    $tr == TRPassed
}

method send-plan(UInt:D $planned, :$on-start) {
    # say "send plan of $planned, on start? ", ?$on-start;
    # say "skip message: “{$!skip-message || '*none*'}”";
    if $on-start && !$!parent-suite && $!skip-message.defined {
        self.report-event: Event::Plan.new( :origin(self), :skip, :message($!skip-message), :planned(0) );
        exit 0;
    }
    self.send: Event::Plan, :$planned;
}

# Normal message form is a list of lines ending with newline.
method normalize-message(+@message) {
    @message.join.split("\n").map(* ~ "\n")
}

method send-message(+@message) {
    my @msg = self.normalize-message(@message);
    if $!parent-suite {
        # Collect the message if we're a child
        self.send-command: Event::Cmd::Message, @msg;
    }
    else {
        self.message-to-console: @msg;
    }
}

proto method proclaim(::?CLASS:D: |) {*}
multi method proclaim(::?CLASS:D: Test::Async::Result:D $result, Str:D $message, *%c --> Bool:D) {
    self.proclaim(.cond, $message, .event-profile, |%c) given $result;
}
multi method proclaim(::?CLASS:D: Bool(Mu) $cond, Str:D $message, %ev-profile?, *%c --> Bool:D) {
    my \evType = $cond ?? Event::Ok !! Event::NotOk;
    my %profile = :origin(self),
                  :@!messages,
                  :$!nesting,
                  |%ev-profile;
    my $test-result = $cond || %profile<todo> ?? TRPassed !! TRFailed;
    self.send-test: evType, $message, $test-result, %profile, |%c
}

method next-test-id {
    loop {
        my $cur-id = $!next-test-id;
        if cas($!next-test-id, $cur-id, $cur-id + 1) == $cur-id {
            return $cur-id;
        }
    }
}

method take-TODO(::?CLASS:D: --> Str) {
    my $todo-msg := Nil;
    cas $!TODO-count, {
        $_ > 0
            ?? do { $todo-msg := $!TODO-message; $_ - 1 }
            !! $_
    };
    $todo-msg
}

method set-todo(::?CLASS:D: Str:D $message, Numeric:D $count) {
    self.send-command: Event::Cmd::SetTODO, $message, $count;
}

method sync-events {
    my $synced = Promise.new;
    self.send-command: Event::Cmd::SyncEvents, $synced.vow;
    await $synced;
}

method await-jobs {
    if $!random {
        # Get randomized list of children
        for @.postponed.pick(*) -> $job {
            self.invoke-job: $job
        }
        @.postponed = [];
    }
    # Use a dummy class because with Any in $all-done cas() sometimes fails to update the scalar.
    my class NotDoneYet { }
    my $all-done = NotDoneYet;
    # self.trace-out: ">>> AWAIT JOBS TIMEOUT: ", $!job-timeout;
    await Promise.anyof(
        Promise.in($!job-timeout).then({ cas($all-done, NotDoneYet, False) }),
        start {
            CATCH {
                self.fatality(exception => $_);
                .rethrow
            };
            self.await-all-jobs;
            cas($all-done, NotDoneYet, True);
        }
    );
    # self.trace-out: ">>> JOBS AWAIT DONE: ", $all-done;
    unless $all-done {
        self.throw(Test::Async::X::AwaitTimeout, :what('remaining jobs'))
    }
    self.send: Event::JobsAwaited;
}

method finish(:$now = False) {
    CATCH {
        default {
            self.fatality(255, exception => $_);
        }
    }
    # Only do the sequence once even if accidentally called concurrently.
    return if $!stage == TSFinishing | TSFinished | TSDismissed | TSFatality;
    if self.set-stage(TSFinishing) == TSInProgress {
        # Wait untils all jobs are completed.
        self.await-jobs unless $now;
        self.set-stage(TSFinished);
        # Let all events be processed before we start analyzing the results.
        self.sync-events;
        # Same as plan, done-testing must be done in the main thread.
        self.send-plan: $!tests-run unless $.planned; # If $.planned is set then the plan has been reported on start.
        self.send: Event::DoneTesting;
        self.sync-events; # Wait until all queued events processed;
        self.dismiss;
    }
}

method dismiss {
    return if $!stage == TSDismissed;
    if self.set-stage(TSDismissed) != TSDismissed {
        my $term-ev = self.create-event: Event::Terminate;
        self.send: $term-ev;
        await $term-ev.terminated;
        $!completed-vow.keep((!$!planned || $!tests-run == $!planned) && !$!tests-failed);
    }
}

# TODO This method is more of a stub and needs more thinking over and re-implementing.
method measure-telemetry(&code, Capture:D \c = \()) is hidden-from-backtrace is raw {
    my $st = now;
    LEAVE {
        my $et = now;
        self.try-send: Event::Telemetry, :elapsed($et-$st)
    }
    &code(|c)
}

method push-tool-caller(ToolCallerCtx:D $ctx) {
    @*TEST-TOOL-STACK.push: $ctx
}

method pop-tool-caller(--> ToolCallerCtx:D) {
    fail Test::Async::X::EmptyToolStack.new(:suite(self), :op<pop>)
        unless @*TEST-TOOL-STACK.elems;
    @*TEST-TOOL-STACK.pop
}

proto method anchor(::?CLASS:D: |) {*}
multi method anchor(::?CLASS:D: &code) {
    self.anchor: 2, &code
}
multi method anchor(::?CLASS:D: Int:D $pre-skip, &code) {
    self.push-tool-caller: self.locate-tool-caller($pre-skip + 1, :anchored);
    LEAVE self.pop-tool-caller;
    &code()
}

# Determine the caller and the context.
# Don't make tests guessing what is our caller's context.
method locate-tool-caller(Int:D $pre-skip, Bool:D :$anchored = False --> ToolCallerCtx:D) {
    if (my $anch = (self.tool-caller // $!suite-caller)) andthen .anchored {
        return $anch;
    }
    return $!suite-caller if $!transparent;
    my $ctx = CALLER::;
    my Int:D $idx = 0;
    my $job-id = ($*TEST-JOB ?? $*TEST-JOB.id !! -1);
    my $th-id = $*THREAD.id;
    # note "[$th-id / $job-id] ??? LOOK FOR CTX\n", Backtrace.new.full.Str.indent(4);
    loop {
        # Skip as many frames as requested + own frame
        last unless (my $frame = callframe($idx + 1)) && $frame.file.defined;
        # note "[$th-id / $job-id] FRAME $idx/$pre-skip: ", $frame.code.name, " // ", $frame.file, ":", $frame.line, "\n",
        #     $frame.annotations.keys.map({ $_ => $frame.annotations{$_} }).join("\n").indent(4);
        unless $idx < $pre-skip
            || $frame.file.starts-with('SETTING::' | 'NQP::')
            || $frame.file.ends-with('.nqp')
            || $frame.file.contains('CORE.setting')
            || $ctx<LEXICAL>.WHO<::?PACKAGE>.^name.starts-with('Test::Async::')
        {
            return ToolCallerCtx.new: :$frame, :stash($ctx), :$anchored;
        }
        ++$idx;
        $ctx = $ctx<CALLER>.WHO;
    }
    # No appropriate frame in the stack is most likely caused by a frame optimized away. In case it happened to a code
    # invoked via Promise we still have a chance of accessing its dynamic context.
    if @*TEST-TOOL-STACK {
        # note "[$th-id / $job-id] !!! PICK THE CONTEXT FROM PROMISE OUTERS";
        return @*TEST-TOOL-STACK.tail
    }
    # note "[$th-id / $job-id] !!! NO TOOL CALLER";
    fail Test::Async::X::NoToolCaller.new(:suite(self));
}

method tool-caller(--> ToolCallerCtx:D) {
    fail Test::Async::X::EmptyToolStack.new(:op<tool-caller>, :suite(self)) unless +@*TEST-TOOL-STACK;
    @*TEST-TOOL-STACK.tail
}

my atomicint $temp-count = 0;
method temp-file(Str:D $base-name, $data) {
    my $fname = $*TMPDIR.add(
                    ( 'test-async',
                      $base-name,
                      ($*PID // Empty),
                      (++⚛$temp-count).fmt('%06d'),
                    ).join("-")
                ).absolute;
    my $fh = $fname.IO.open: :w;
    self.throw: Test::Async::X::FileCreate, :$fname, :details($fh.exception.message) unless $fh.so;
    $fh.print: $data;
    $fh.close
        notandthen self.throw(Test::Async::X::FileClose, :$fname, :details(.exception.message));
    $fname
}

# Make sure that if a tool is called from a non-job manager thread then it wouldn't compete for the tool stack with
# tools in other threads
method jobify-tool(&code) {
    if self.thread !=== $*THREAD && !$*TEST-SUITE {
        return await self.invoke-job: self.new-job(&code)
    }
    &code()
}

# Returns a list of "&tool-name" => &code pairs
method tool-factory(--> Seq:D) {
    (self, |self.HOW.bundles)
        .map( |*.^methods )
        .grep(Test::Async::TestTool)
        .map: -> \meth {
            my $name = meth.tool-name;
            my $meth = meth.name;
            my &code = my sub (|c) is raw { test-suite()."$meth"(|c) };
            &code.set_name($name);
            "&" ~ $name => &code
        }
}

method in-fatality(Bool:D :$local = False) {
    ⚛$!stage == TSFatality
    || (
        !$local
        && $.parent-suite
        && $.parent-suite.in-fatality(:$local)
    )
}

method fatality(Int:D $!exit-code = 255, Exception :$exception) {
    my %params;
    with $exception {
        self.x-sorry: $_;
        %params<exception> = $_;
    }
    self.set-stage(TSFatality, :%params);
    $!tests-failed = 1 unless $!tests-failed;
    with $.parent-suite {
        .fatality($!exit-code, :$exception)
    }
    else {
        with &!EXIT {
            .(self.exit-code)
        }
        exit self.exit-code
    }
}

method x-sorry(Exception:D $ex, :$comment --> Nil) {
    my $succeed = try {
        note "===SORRY!=== Suite #" ~ $.id ~ " '" ~ $.message ~ "', ", $.suite-caller.frame.gist, ":\n"
            ~ ($ex ~~ Test::Async::X::Base
                    ?? ("thrown by suite #"
                        ~ $ex.suite.id
                        ~ " '"
                        ~ $ex.suite.message
                        ~ "', "
                        ~ $ex.suite.suite-caller.frame.gist
                        ~ "\n").indent(2)
                    !! "")
            ~ ($comment ?? ($comment ~ "\n").indent(2) !! "")
            ~ ("[" ~ $ex.^name ~ "] " ~ $ex.message ~ "\n" ~ $ex.backtrace).indent(4)
    };
    unless $succeed {
        with $! -> $sec {
            note "===FAIL!=== ", $sec.^name, " was thrown while reporting ", $ex.^name, ": ",
                (try { $sec.message } // "*** can't produce a message for the secondary exception ***"), "\n",
                (
                    ("The original exception message: " ~ (try { $ex.message } // "*** can't produce the message ***")),
                    ("The original backtrace:\n" ~ $ex.backtrace.Str.indent(2))
                ).join("\n").indent(2), "\n",
                $sec.backtrace.full.Str;
        }
        else {
            note "===FAIL!=== Can't report exception ", $ex.^name,
                (try { ': "' ~ $ex.message ~ '"'  } // ""), ", original backtrace:\n",
                .backtrace.Str.indent(4);
        }
    }
}

# Implementation detail, for use with a wrapper script I use for parallelized testing.
method trace-out(**@out) {
    return unless $.trace-mode || $*TEST-ASYNC-TRACING;
    my $out-file = "TestAsync-" ~ (%*ENV<TEST_PARALLEL_ID> // $*PID) ~ ".trace";
    my $traceh = $out-file.IO.open: :a, :out-buffer(0);
    LEAVE { .close with $traceh };
    my $lines = @out.map(*.gist)
                    .join
                    .split(/\n/)
                    .map({ sprintf "[%5d:%8d] %s\n", $.id, $*PID, $_ })
                    .join;
    $traceh.print: $lines;
}
