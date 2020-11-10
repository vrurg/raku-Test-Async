NAME
====

`Test::Async::Hub` - the core of `Test::Async` framework

SYNOPSIS
========

    if test-suite.random {
        say "The current suite is in random mode"
    }

DESCRIPTION
===========

Consumes [`Test::Async::Aggregator`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Aggregator.md), [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/JobMgr.md)

See [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Manual.md) for general purpose of this class.

Command Execution
-----------------

All events whose class derives from `Event::Command` are handled in a special manner. Class name of such event is used to form a method name. Corresponding method is then invoked with a [`Capture`](https://docs.raku.org/type/Capture) passed in event's attribute `$.args`. For example, to mark all remaining tests as skipped, event `Event::Cmd::SkipRemaining` is used. Based on the class, method `cmd-skipremaining` is invoked with a single positional string argument in `$.args` containing the skip message if the event has been created without an error.

Method `send-command` is recommended to emit command messages.

See method `set-todo` or `sync-events` for an example of using this interface.

ATTRIBUTES
==========

`parent-suite`
--------------

If defined then it's the suite which invoked the current one.

`message`
---------

Message associated with this suite. Only makes sense for children.

`code`
------

The code block associated with the suite. Undefined for the top one.

`completed`
-----------

A [`Promise`](https://docs.raku.org/type/Promise) instance which is fulfilled when `done-testing` is executed.

`planned`
---------

The number of tests planned for this suite. Undefined if no plans were made.

`skip-message`
--------------

If suite is planned for skipping then this is the message as for `skip-remaining` tool:

    subtest "Conditional test" => {
        plan |($condition ?? :skip-all('makes no sens because ...') !! Empty);
        pass "dummy test";
    }

Otherwise undefined.

**NOTE!** Any examples of code in this documentation are based on the default [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Base.md) bundle.

`TODO-message`
--------------

If suite is planned for *TODO* then this is the message as for any of `todo` test tools.

`TODO-count`
------------

A number of remaining *TODO* tests:

    todo "To be done yet...", 3;
    pass  "test 1";
    # -> test-suite.TODO-count == 2 at this point
    flunk "test 2";
    pass  "test 3";

Could be set to `Inf` meaning all remaining tests are to be *TODO*-marked.

`nesting`
---------

How deep are we from the top suite? I.e. a child of a child of the top suite will have nesting 2.

`nesting-prefix`
----------------

A string, recommended prefix to be used for indenting messages produced by the suite.

`tool-caller`
-------------

An instance of `CallFrame`. If defined then it's where the last test tool has been invoked.

`suite-caller`
--------------

Similar to `test-tool` above but it's where the suite itself was invoked.

`caller-ctx`
------------

If defined then this is the context in which the last test tool has been invoked.

`transparent`
-------------

A flag. If *True* then this suite will have its `tool-caller` and `caller-ctx` attributes set to the same values, as in parent's suite object. `subtest` implementation by [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Base.md) uses this to implement `:hidden` mode of operation.

This attribute is propagated to child suites instantiated using `create-suite` method.

`is-async`
----------

True if the suite itself or any of its parents is invoked asynchronously.

`is-TODO`
---------

Indicates if the whole suite has been marked as *TODO*. This makes difference between:

    todo "Later...";
    subtest "new feature" => { ... }

and

subtest "new feature" => { todo-remaining "Later..."; ... }

Also *True* if `todo` parameter of plan is set to a message, which is virtually the same as prefixing the subtest with `todo`.

`parallel`
----------

*True* if suite is invoking children suites asynchronously.

`random`
--------

*True* if suite is invoking children suites in a random order.

`tests-run`
-----------

The counter of test tool invocations.

`tests-failed`
--------------

The counter of failed test tools.

`messages`
----------

An array of message lines produced by the suite and its child suites if it is an asynchronous child. I.e. if `is-async` is *True*. The messages are submitted for reporting when the suite run ends and its result is reported.

`test-jobs`
-----------

Maximus number of concurrently running jobs allowed. Note that a *job* is anything invoked using `start-job` method of [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/JobMgr.md).

`stage`
-------

The current stage of suite lifecycle. See `TestStage` enum in [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Utils.md).

METHODS
=======

`new`
-----

Creates a new instance of constructed `Test::Async::Suite` class. See [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Manual.md).

`top-suite()`
-------------

Returns a singleton – the top suite object.

`has-top-suite()`
-----------------

Returns `True` if the top suite singleton has been instantiated already.

`set-stage(TestStage:D $stage -` TestStage)>
--------------------------------------------

Transition suite state to stage `$stage`. Throws `X::StageTransition` ([`Test::Async::X`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/X.md)) if the transition is not possible. If transitions from `TSInitializing` to `TSInProgress` then the method also starts the event loop thread.

Returns the pre-transition stage.

`set-tool-caller(CallFrame:D $caller)`
--------------------------------------

Sets `tool-caller` attribute.

`set-caller-ctx($ctx)`
----------------------

Sets `caller-ctx` attribute. `$ctx` could be a `Stash` or a `PseudoStash`.

`multi event(Event:D)`
----------------------

The ultimate handler of event objects. A bundle wishing to react to events must define a multi-candidate of this method:

    test-bundle MyBundle {
        multi method event(Event::Telemetry:D $ev) {
            ...
        }
    }

`setup-from-plan`
-----------------

Setup suite parameters based on a plan profile hash. If called when suite stage is not `TSInitializing` then throws `X::PlanTooLate`.

The keys supported by profile are:

  * **tests** - planned number of tests.

  * **skip-all** - a string with a skip message. If set all tests are skipped as if `skip-remaining` is used.

  * **todo** - a string with a *TODO* message. If set all tests and suite itself are marked as *TODO*.

  * **parallel** – invoke children suites asynchronously.

  * **random** – invoke children suites randomly.

  * **test-jobs** - set the maximum number of concurrent jobs allowed. See `$.test-jobs`.

  * **job-timeout** - set the timeout awaiting for jobs to complete. See `$.job-timeout`.

`multi plan(UInt:D $tests, *%profile)`
--------------------------------------

`multi plan(*%profile)`
-----------------------

One of the only two test tools provided by the core itself. See method `setup-from-plan` for the profile keys allowed.

When `plan` is invoked with positional integer parameter, this is equivalent to setting `tests` plan profile key. In either case, if tests are planned the method reports it by emitting `Event::Plan`.

If plan profile contains unknown keys then diagnostic event with a warning is emitted for each unknwon key.

`done-testing()`
----------------

Just invokes `finish` method.

`create-suite(suiteType = self.WHAT, *%c)`
------------------------------------------

Creates a child suite. `%c` is used to pass parameters to the suite constructor method.

`invoke-suite($suite, :$async = False, :$instant = False, Capture:D :$args=\())`
--------------------------------------------------------------------------------

Invokes a suite as a new job. The invocation method chosen depending on the suite `parallel` and `random` attributes and this method parameters. The parameters take precedence over the attributes:

  * **`$instant`** - start job instantly, ignore the value of `random`.

  * **`$async`** - start job asynchronously always. If `random` is in effect then job is postponed but then would start asynchronously anyway, not matter of `parallel`.

  * **`$args`** – a [`Capture`](https://docs.raku.org/type/Capture) which will be used to call `$suite`'s code.

The method returns job `Promise` of the invoked suite.

`run(:$is-async)`
-----------------

Execute the suite here and now. Internal implementation detail.

`throw(X::Base:U \exType, *%c)`
-------------------------------

Throws a [`Type::Async::X`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Type/Async/X.md) exception. `%c` is used as exception constructor profile to which `hub` named parameter is added.

`abort`
-------

Results in quick suite shutdown via bypassing all remaining suite code and invoking method `dismiss`.

`send-command(Event::Command:U \evType, |c)`
--------------------------------------------

Sends a command message event. The `c` capture is passed with the event object and is used as parameters of the command handling method.

`multi send-test(Event::Test:U \evType, Str:D $message, TestResult:D $test-result, *%c --` Bool)>
-------------------------------------------------------------------------------------------------

Creates an event of type `evType` and emits it. This is *the* method to be used for emitting `Event::Test`.

The method:

  * counts tests, including total runs and failures

  * marks a test as *TODO* (see `take-TODO` method)

  * sets test number

  * sets event's `caller` attribute

`send-plan(UInt:D $planned, :$on-start)`
----------------------------------------

Emits `Event::Plan` event. If `$on-start` is *True* and suite is the topmost one with `skip-all` passed in plan profile – in other words, if topmost suite is planned for skipping; – then instead of emitting the event by standard means, hands it over directly to `report-event` method and instantly exits the program with 0 exit code.

`normalize-message(+@message --` Seq)>
--------------------------------------

Takes a free-form message possible passed in in many chunks, splits it into lines and appends a new line to each individual line. This is the *normal form* of a message. [`Test::Async::Reporter::TAP`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Reporter/TAP.md) expects children suite messages to come in normalized form.

*NOTE.* This form is chosen as *normal* because TAP is a line-based protocol for which a line must end with a newline.

`send-message(+@message)`
-------------------------

This method takes a message, normalizes it, and then choses which output channel it is to be directed to:

= if suite is not the topmost one and it its `$.is-async` is *True* then message is collected in `@.messages` to be later passed to the parent suite with a test event. = otherwise the message is passed to `method-to-console` method.

`multi proclaim(Test::Async::Result:D $result, Str:D $message)`
---------------------------------------------------------------

`multi proclaim(Bool $cond, Str:D $message, $event-profile)`
------------------------------------------------------------

This is the main method to emit a test event depending on test outcome passed in `$cond` or `$result.cond`. The method sets event `origin` to the invoking object, sets event's object `@.messages` and `$.nesting`. `$event-profile` is what the user wants to supply to `Event::Test` constructor.

`next-test-id`
--------------

Returns the next available test number. This is the number one sees next to test outcome status:

    ok 2 - message
       ^
       +--- this is it!

`take-TODO(--` Str)>
--------------------

If suit has a *TODO* in effect, i.e. `$.is-TODO` is *True* or `$!TODO-count` is greater than 0, then this method will return the current `$.TODO-message`. The `$.TODO-count` will be reduced if necessary.

`set-todo(Str:D $message, Int:D $count)`
----------------------------------------

Emits `Event::Cmd::SetTODO`.

`sync-events()`
---------------

It's almost no-op method call with a side effect of making sure that all events emitted prior to this method call are processed. The method works by emitting `Event::Cmd::SyncEvents` with a `Promise::Vow` parameter and awaits until `cmd-syncevents` command handler keeps the vow. Because events are queued, this ensures that by the moment when the vow is kept all earlier events in the queue were pulled and handled.

`await-jobs()`
--------------

This method implements two tasks:

  * first, it pulls postponed jobs and invokes them in a random order

  * next it calls `await-all-jobs` to make sure all jobs have completed

  * if `await-all-jobs` doesn't finish in 30 seconds `X::AwaitTimeout` is thrown

`finish(:$now = False)`
-----------------------

This is the finalizing method. When suite ends, it invokes this method to take care of postponed jobs, report a plan if not reported at suite start (i.e. number of planned tests wasn't set), and emits `Event::DoneTesting` and `Event::Terminate`.

While performing these steps the method transition from `TSFinishing` stage, to `TSFinished`, and then calls method `dismiss`.

With `:now` the method ignores any postponed job and proceeds as if none were started. This is a kind of an emergency hatch for cases where we have good reasons to suspect a stuck job.

`dismiss`
---------

Transition suite to `TSDismissed` stage and emits `Event::Terminate`. After that it awaits for the event to be handled by the event loop.

`measure-telemetry(&code, Capture:D \c = \())`
----------------------------------------------

This method is for the future implementation and doesn't really do anything useful now.

`tool-factory(--` Seq)>
-----------------------

Produces a sequence of `'&tool-name' =` &tool-code> pairs suitable for use with `sub EXPORT`. Internal implementation detail.

`locate-tool-caller(Int:D $pre-skip)`
-------------------------------------

Finds the context in which the current test tool is invoked. Sets `tool-caller` and `caller-ctx` attributes.

`temp-file(Str:D $base-name, $data --` Str:D)>
----------------------------------------------

Quickly create a temporary file and populate it with $data. Returns absolute file name. Throws `X::FileCreate`/`X::FileClose` in case of errors.

SEE ALSO
========

[`Test::Async::Aggregator`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Aggregator.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Decl.md), [`Test::Async::Event`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Event.md), [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/JobMgr.md), [`Test::Async::Result`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Result.md), [`Test::Async::TestTool`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/TestTool.md), [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Utils.md), [`Test::Async::X`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/X.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

