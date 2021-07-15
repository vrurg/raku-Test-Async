use v6;

=begin pod
=head1 NAME

C<Test::Async::Hub> - the core of C<Test::Async> framework

=head1 SYNOPSIS

    if test-suite.random {
        say "The current suite is in random mode"
    }

=head1 DESCRIPTION

Consumes L<C<Test::Async::Aggregator>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Aggregator.md>,
L<C<Test::Async::JobMgr>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/JobMgr.md>

See L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Manual.md>
for general purpose of this class.

=head2 Command Execution

All events whose class derives from C<Event::Command> are handled in a special manner. Class name of such event is used
to form a method name. Corresponding method is then invoked with a L<C<Capture>|https://docs.raku.org/type/Capture>
passed in event's attribute C<$.args>.  For example, to mark all remaining tests as skipped, event
C<Event::Cmd::SkipRemaining> is used. Based on the class, method C<cmd-skipremaining> is invoked with a single
positional string argument in C<$.args> containing the skip message if the event has been created without an error.

Method C<send-command> is recommended to emit command messages.

See method C<set-todo> or C<sync-events> for an example of using this interface.

=head1 ATTRIBUTES

=head2 C<parent-suite>

If defined then it's the suite which invoked the current one.

=head2 C<message>

Message associated with this suite. Only makes sense for children.

=head2 C<code>

The code block associated with the suite. Undefined for the top one.

=head2 C<completed>

A L<C<Promise>|https://docs.raku.org/type/Promise> instance which is fulfilled when C<done-testing> is executed.

=head2 C<planned>

The number of tests planned for this suite. Undefined if no plans were made.

=head2 C<skip-message>

If suite is planned for skipping then this is the message as for C<skip-remaining> tool:

    subtest "Conditional test" => {
        plan |($condition ?? :skip-all('makes no sens because ...') !! Empty);
        pass "dummy test";
    }

Otherwise undefined.

B<NOTE!> Any examples of code in this documentation are based on the default
L<C<Test::Async::Base>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Base.md>
bundle.

=head2 C<TODO-message>

If suite is planned for I<TODO> then this is the message as for any of C<todo> test tools.

=head2 C<TODO-count>

A number of remaining I<TODO> tests:

    todo "To be done yet...", 3;
    pass  "test 1";
    # -> test-suite.TODO-count == 2 at this point
    flunk "test 2";
    pass  "test 3";

Could be set to C<Inf> meaning all remaining tests are to be I<TODO>-marked.

=head2 C<nesting>

How deep are we from the top suite? I.e. a child of a child of the top suite will have nesting 2.

=head2 C<nesting-prefix>

A string, recommended prefix to be used for indenting messages produced by the suite.

=head2 C<suite-caller>

An instance of
L<C<Test::Async::Hub::ToolCallerCtx>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Hub/ToolCallerCtx.md>.
Keeps information about the location where the suite was created.

=head2 C<transparent>

A flag. If I<True> then this suite will have its call location set to the where it's enclosing test tool or suite
are called. C<subtest> implementation by
L<C<Test::Async::Base>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Base.md>
uses this for C<:hidden> mode of operation.

This attribute is propagated to child suites instantiated using C<create-suite> method. In other words, nested
suites of a transparent one will all be transparent by default.

=head2 C<is-async>

True if the suite itself or any of its parents is invoked asynchronously.

=head2 C<is-TODO>

Indicates if the whole suite has been marked as I<TODO>. This makes difference between:

    todo "Later...";
    subtest "new feature" => { ... }

and

subtest "new feature" => {
    todo-remaining "Later...";
    ...
}

Also I<True> if C<todo> parameter of plan is set to a message, which is virtually the same as prefixing the subtest with
C<todo>.

=head2 C<parallel>

I<True> if suite is invoking children suites asynchronously.

=head2 C<random>

I<True> if suite is invoking children suites in a random order.

=head2 C<tests-run>

The counter of test tool invocations.

=head2 C<tests-failed>

The counter of failed test tools.

=head2 C<messages>

An array of message lines produced by the suite and its child suites if it is an asynchronous child. I.e. if C<is-async>
is I<True>. The messages are submitted for reporting when the suite run ends and its result is reported.

=head2 C<test-jobs>

Maximus number of concurrently running jobs allowed. Note that a I<job> is anything invoked using C<start-job> method
of L<C<Test::Async::JobMgr>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/JobMgr.md>.

=head2 C<stage>

The current stage of suite lifecycle. See C<TestStage> enum in
L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Utils.md>.

=head1 METHODS

=head2 C<new>

Creates a new instance of constructed C<Test::Async::Suite> class. See
L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Manual.md>.

=head2 C<top-suite()>

Returns a singleton – the top suite object.

=head2 C<has-top-suite()>

Returns C<True> if the top suite singleton has been instantiated already.

=head2 C<set-stage(TestStage:D $stage -> TestStage)>

Transition suite state to stage C<$stage>. Throws C<X::StageTransition>
(L<C<Test::Async::X>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/X.md>) if the transition is not possible. If transitions from C<TSInitializing> to C<TSInProgress> then
the method also starts the event loop thread.

Returns the pre-transition stage.

=head2 C<multi event(Event:D)>

The ultimate handler of event objects. A bundle wishing to react to events must define a multi-candidate of this method:

    test-bundle MyBundle {
        multi method event(Event::Telemetry:D $ev) {
            ...
        }
    }

=head2 C<setup-from-plan>

Setup suite parameters based on a plan profile hash. If called when suite stage is not C<TSInitializing> then throws
C<X::PlanTooLate>.

The keys supported by profile are:

=item B<tests> - planned number of tests.
=item B<skip-all> - a string with a skip message. If set all tests are skipped as if C<skip-remaining> is used.
=item B<todo> - a string with a I<TODO> message. If set all tests and suite itself are marked as I<TODO>.
=item B<parallel> – invoke children suites asynchronously.
=item B<random> – invoke children suites randomly.
=item B<test-jobs> - set the maximum number of concurrent jobs allowed. See C<$.test-jobs>.
=item B<job-timeout> - set the timeout awaiting for jobs to complete. See C<$.job-timeout>.

=head2 C<multi plan(UInt:D $tests, *%profile)>
=head2 C<multi plan(*%profile)>

One of the only  two test tools provided by the core itself. See method C<setup-from-plan> for the profile keys allowed.

When C<plan> is invoked with positional integer parameter, this is equivalent to setting C<tests> plan profile key. In
either case, if tests are planned the method reports it by emitting `Event::Plan`.

If plan profile contains unknown keys then diagnostic event with a warning is emitted for each unknwon key.

=head2 C<done-testing()>

Just invokes C<finish> method.

=head2 C<abort-testing()>

Similar to C<done-testing> but also interrupts current test suite. If it happens to be the C<top-suite> then exits.

This tool is helpful to avoid constructs like:

    if !ok($my-check-result, "...") {
        skip-rest "other tests make no sense now";
    }
    else {
        ... # Do all other tests
    }

Such approach could be especially annoying if I<other tests> also have a case where failure must skip remaining tests.
Instead one can do:

    if !ok($my-check-result, "...") {
        skip-rest "other tests make no sense now";
        abort-testing
    }
    ... # Do more tests
    if !ok($my-other-check, "...") {
        skip-rest "makes no sense to proceed";
        abort-testing
    }
    ... # Do the rest

=head2 C<create-suite(suiteType = self.WHAT, *%c)>

Creates a child suite. C<%c> is used to pass parameters to the suite constructor method.

=head2 C<invoke-suite($suite, :$async = False, :$instant = False, Capture:D :$args=\())>

Invokes a suite as a new job. The invocation method chosen depending on the suite C<parallel> and C<random> attributes
and this method parameters. The parameters take precedence over the attributes:

=item B<C<$instant>> - start job instantly, ignore the value of C<random>.
=item B<C<$async>> - start job asynchronously always. If C<random> is in effect then job is postponed but then would
start asynchronously anyway, not matter of C<parallel>.
=item B<C<$args>> – a L<C<Capture>|https://docs.raku.org/type/Capture> which will be used to call C<$suite>'s code.

The method returns job C<Promise> of the invoked suite.

=head2 C<run(:$is-async)>

Execute the suite here and now. Internal implementation detail.

=head2 C<throw(X::Base:U \exType, *%c)>

Throws a L<C<Type::Async::X>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Type/Async/X.md> exception. C<%c> is used as exception constructor profile to which C<hub> named parameter
is added.

=head2 C<abort>

Results in quick suite shutdown via bypassing all remaining suite code and invoking method C<dismiss>.

=head2 C<send-command(Event::Command:U \evType, |c)>

Sends a command message event. The C<c> capture is passed with the event object and is used as parameters of the command
handling method.

=head2 C<multi send-test(Event::Test:U \evType, Str:D $message, TestResult:D $test-result, *%event-profile --> Bool:D)>
=head2 C<multi send-test(Event::Test:U \evType, Str:D $message, TestResult:D $test-result, %event-profile, Bool :$bypass-todo --> Bool:D)>

Creates an event of type C<evType> and emits it. This is I<the> method to be used for emitting C<Event::Test>.

`send-test` does the following:

=item counts tests, including total runs and failures
=item marks a test as I<TODO> unless `:bypass-todo` argument is given (see C<take-TODO> method)
=item sets test number
=item sets event's C<caller> attribute

=head2 C<send-plan(UInt:D $planned, :$on-start)>

Emits C<Event::Plan> event. If C<$on-start> is I<True> and suite is the topmost one with C<skip-all> passed in plan
profile – in other words, if topmost suite is planned for skipping; – then instead of emitting the event by standard
means, hands it over directly to C<report-event> method and instantly exits the program with 0 exit code.

=head2 C<normalize-message(+@message --> Seq)>

Takes a free-form message possible passed in in many chunks, splits it into lines and appends a new line to each
individual line. This is the I<normal form> of a message.
L<C<Test::Async::Reporter::TAP>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Reporter/TAP.md>
expects children suite messages to come in normalized form.

I<NOTE.> This form is chosen as I<normal> because TAP is a line-based protocol for which a line must end with a newline.

=head2 C<send-message(+@message)>

This method takes a message, normalizes it, and then choses which output channel it is to be directed to:

= if suite is not the topmost one and it its C<$.is-async> is I<True> then message is collected in C<@.messages> to be
later passed to the parent suite with a test event.
= otherwise the message is passed to C<method-to-console> method.

=head2 C<multi proclaim(Test::Async::Result:D $result, Str:D $message, *%c --> Bool:D)>
=head2 C<multi proclaim(Bool $cond, Str:D $message, %event-profile, *%c --> Bool:D)>

This is the main method to emit a test event depending on test outcome passed in C<$cond> or C<$result.cond>. The method
sets event C<origin> to the invoking object, sets event's object C<@.messages> and C<$.nesting>. C<%event-profile> is
what the user wants to pass to C<Event::Test> constructor. C<%c> capture is bypassed to `send-test` method as-is.

=head2 C<next-test-id>

Returns the next available test number. This is the number one sees next to test outcome status:

    ok 2 - message
       ^
       +--- this is it!

=head2 C<take-TODO(--> Str)>

If suit has a I<TODO> in effect, i.e. C<$.is-TODO> is I<True> or C<$!TODO-count> is greater than 0, then this method
will return the current C<$.TODO-message>. The C<$.TODO-count> will be reduced if necessary.

=head2 C<set-todo(Str:D $message, Int:D $count)>

Emits C<Event::Cmd::SetTODO>.

=head2 C<sync-events()>

It's almost no-op method call with a side effect of making sure that all events emitted prior to this method call are
processed. The method works by emitting C<Event::Cmd::SyncEvents> with a C<Promise::Vow> parameter and awaits until
C<cmd-syncevents> command handler keeps the vow. Because events are queued, this ensures that by the moment when the vow
is kept all earlier events in the queue were pulled and handled.

=head2 C<await-jobs()>

This method implements two tasks:

=item first, it pulls postponed jobs and invokes them in a random order
=item next it calls C<await-all-jobs> to make sure all jobs have completed
=item if C<await-all-jobs> doesn't finish in 30 seconds C<X::AwaitTimeout> is thrown

=head2 C<finish(:$now = False)>

This is the finalizing method. When suite ends, it invokes this method to take care of postponed jobs, report a plan
if not reported at suite start (i.e. number of planned tests wasn't set), and emits C<Event::DoneTesting> and
C<Event::Terminate>.

While performing these steps the method transition from C<TSFinishing> stage, to C<TSFinished>, and then calls method
C<dismiss>.

With C<:now> the method ignores any postponed job and proceeds as if none were started. This is a kind of an emergency
hatch for cases where we have good reasons to suspect a stuck job.

=head2 C<dismiss>

Transition suite to C<TSDismissed> stage and emits C<Event::Terminate>. After that it awaits for the event to be handled
by the event loop.

=head2 C<measure-telemetry(&code, Capture:D \c = \())>

This method is for the future implementation and doesn't really do anything useful now.

=head2 C<tool-factory(--> Seq)>

Produces a sequence of C<'&tool-name' => &tool-code> pairs suitable for use with C<sub EXPORT>. Internal implementation
detail.

=head2 C<locate-tool-caller(Int:D $pre-skip, Bool:D :$anchored --> ToolCallerCtx:D)>

Finds the context in which the current test tool is invoked and returns a
L<C<Test::Async::Hub::ToolCallerCtx>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Hub/ToolCallerCtx.md>
instance or a L<C<Failure>|https://docs.raku.org/type/Failure> in case of an error.

C<$pre-skip> defines the number of frames to be skipped before the method starts looking for the real call location.
The value must be relative to the frame where the method is called.

=head3 C<push-tool-caller(ToolCallerCtx:D $ctx)>

Pushes a new call location on tool call stack.

=head3 C<pop-tool-caller(--> ToolCallerCtx:D)>

Pops a call location from tool call stack. Returns L<C<Failure>|https://docs.raku.org/type/Failure> if the stack is empty.

=head2 C<tool-caller(--> ToolCallerCtx:D)>

Returns the topmost call location on the tool call stack or a L<C<Failure>|https://docs.raku.org/type/Failure> if the stack is empty.

=head2 C<anchor(&code)>, C<anchor(Int:D $pre-skip, &code)>

This method sets anchor location (see
L<C<Type::Async::Manual>|https://modules.raku.org/dist/Type::Async::Manual>
Call Location And Anchoring section) for all nested test suits or calls to test tools, done within C<&code>.
For example:

    method my-compound-tool(...) is test-tool(:!wrap) {
        self.anchor: {
            subtest "compound subtest", :hidden, {
                my-other-compound-tool(...);
            }
        }
    }

In the example the subtest and any nested tools/suits used by C<my-other-compound-tool> will report the location where
C<my-compound-tool> is called.

=head2 C<temp-file(Str:D $base-name, $data --> Str:D)>

Quickly create a temporary file and populate it with $data. Returns absolute file name. Throws
C<X::FileCreate>/C<X::FileClose> in case of errors.

=head1 SEE ALSO

L<C<Test::Async::Aggregator>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Aggregator.md>,
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Decl.md>,
L<C<Test::Async::Event>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Event.md>,
L<C<Test::Async::JobMgr>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/JobMgr.md>,
L<C<Test::Async::Result>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Result.md>,
L<C<Test::Async::TestTool>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/TestTool.md>,
L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Utils.md>,
L<C<Test::Async::X>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/X.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

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
has Int $.exit-code;

# Run children in individual threads
has Bool $.parallel;
# Messages collected during test code run.
has Str:D @.messages;
# How many jobs can be invoked in parallel.
has UInt:D $.test-jobs = (try { %*ENV<TEST_JOBS>.Int } || ($*KERNEL.cpu-cores - 2)) max 1;
has $.job-timeout where Int:D | Inf = (%*ENV<TEST_ASYNC_JOB_TIMEOUT> || Inf).Num;

# Debug attributes
has Bool $.trace-mode is rw = ? %*ENV<TEST_ASYNC_TRACING>;  # Tracing writes into output-<id>.trace file

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
            self.throw: X::TransparentWithoutParent
        }
    }
}

my $singleton;
method top-suite {
    # Tool call stack
    PROCESS::<@TEST-TOOL-STACK> = [];
    $singleton //= ::?CLASS.new
}

method has-top-suite {
    $singleton.defined
}

method test-suite {
    $*TEST-SUITE // self.top-suite
}

my @stage-equivalence = TSInitializing, TSInProgress, TSInProgress, TSFinished, TSDismissed, TSDismissed;

method stage { $!stage }

method set-stage(TestStage:D $stage, :%params = {}) {
    return $!stage if $!stage == $stage;
    loop {
        my $cur-stage = $!stage;
        # Prevent possible race condition when two concurrent locations are trying to set different states.
        # States are defined by the equivalence table.
        self.throw: X::StageTransition, :from($cur-stage), :to($stage)
            if @stage-equivalence[$cur-stage] > @stage-equivalence[$stage];
        # Do nothing if requested stage is equivalent to the current one but preceeds it.
        return $cur-stage if $cur-stage > $stage;
        if cas($!stage, $cur-stage, $stage) == $cur-stage {
            self.start-event-loop if $cur-stage == TSInitializing;
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
        self.throw: X::PlanTooLate;
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
        when X::PlanTooLate {
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
        exit;
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
            self.x-sorry: $_;
            # Report failure by having at least one failed test.
            with $!planned {
                $!tests-failed += $!planned - $!tests-run;
            }
            self.fatality(exception => $_)
        }
    }
    $!is-async = ($!parent-suite && $!parent-suite.is-async) || ?$is-async;
    my $*TEST-SUITE = self;
    &!code(|$args);
    # note "SUITE -> FINISH";
    self.finish;
}

method throw(X::Base:U \exType, *%c) is hidden-from-backtrace {
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
method normalize-message(@message) {
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
        Promise.in($!job-timeout).then({ cas($all-done, NotDoneYet, False); }),
        start {
            CATCH {
                self.x-sorry($_);
                self.fatality(exception => $_);
                .rethrow
            };
            self.await-all-jobs;
            cas($all-done, NotDoneYet, True);
        }
    );
    # self.trace-out: ">>> JOBS AWAIT DONE: ", $all-done;
    unless $all-done {
        self.throw(X::AwaitTimeout, :what('all jobs'))
    }
    self.send: Event::JobsAwaited;
}

method finish(:$now = False) {
    # Only do the sequence once even if accidentally called concurrently.
    return if $!stage == TSFinishing | TSFinished | TSDismissed | TSFatality;
    if self.set-stage(TSFinishing) == TSInProgress {
        # Wait untils all jobs are completed.
        self.await-jobs unless $now;
        self.set-stage(TSFinished);
        self.sync-events;
        # Let all event be processed before we start analyzing the results.
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
    fail X::EmptyToolStack.new(:suite(self), :op<pop>)
        unless +@*TEST-TOOL-STACK;
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
    while $ctx {
        # Skip as many frames as requested + own frame
        unless $idx < $pre-skip || $ctx<LEXICAL>.WHO<::?PACKAGE>.^name.starts-with('Test::Async::') {
            return ToolCallerCtx.new: :frame(callframe($idx + 1)), :stash($ctx), :$anchored;
        }
        ++$idx;
        $ctx = $ctx<CALLER>.WHO<LEXICAL>.WHO;
    }
    fail X::NoToolCaller.new(:suite(self));
}

method tool-caller(--> ToolCallerCtx:D) {
    fail X::EmptyToolStack.new(:op<tool-caller>, :suite(self)) unless +@*TEST-TOOL-STACK;
    @*TEST-TOOL-STACK[*-1]
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
    self.throw: X::FileCreate, :$fname, :details($fh.exception.message) unless $fh.so;
    $fh.print: $data;
    $fh.close
        notandthen self.throw(X::FileClose, :$fname, :details(.exception.message));
    $fname
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

method fatality(Int:D $!exit-code = 255) {
    self.set-stage(TSFatality);
    $!tests-failed = 1 unless $!tests-failed;
    with $.parent-suite {
        .fatality($!exit-code)
    }
    else {
        if self.event-queue-is-active {
            self.send-command: Event::Cmd::BailOut, $!exit-code
        }
        else {
            exit $!exit-code
        }
    }
}

method x-sorry(Exception:D $ex, :$comment) {
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
