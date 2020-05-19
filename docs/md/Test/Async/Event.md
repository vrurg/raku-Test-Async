NAME
====

`Test::Async::Event` – collection of standard events

SYNOPSIS
========

    use Test::Async::Event;

    test-bundle MyBundle {
        method foo(Str:D $message) is test-tool {
            self.send-test: Event::Ok, :$message
        }
    }

DESCRIPTION
===========



General information about `Test::Async` event management can be found in [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Manual.md).

Events are objects of classes derived from `Event` class. This module defines events used by the core. In general, all event classes can be conventionally split into the following groups:

  * *informative* – events signalling about some state changes. Like, for example, suite termination.

  * *reporting* - events bearing a message to be reported to user.

  * *commands* – those which tell the core to perform an action.

  * *tests* – outcomes of individual test tools.

EXPORTED CLASSES
================

Class `Event`
-------------

The base event class.

### Attributes

  * `$.origin` – event originating object. Defaults to the current test suite object.

  * `Int:D $.id` – event id, a sequential number.

  * `Instant:D $.time` – the moment when event object was created.

### Methods

  * `Profile` – returns a [`Map`](https://docs.raku.org/type/Map) suitable for passing to an event constructor. The method collects all changed public attributes of an object.

  * `gist`, `Str` – stringify event object for reporting.

Class `Event::Report`
---------------------

Is `Event`.

Base class for events carrying a text message of any kind.

### Attributes

  * `Str:D $.message` – the event message

Class `Event::Command`
----------------------

Is `Event`.

Base class of commanding events. [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Hub.md) handles them specially.

### Attributes

  * `Capture:D $.args` – command arguments

Class `Event::Test`
-------------------

Is `Event::Report`

Base class for events reporting test outcomes.

### Attributes

  * `Str $.todo` – message to use if test is marked as *TODO*.

  * `Str $.flunks` – message to use if test is marked as anticipated failure (see `test-flunks` in [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Base.md).

  * `CallFrame:D $.caller`, required – position in user code where the test was called.

  * `@.child-messages` – messages from child suites. Each entry should be a single line ending with newline.

  * `@.comments` – comments for the test. Normally expected to be reported with `diag`. Not special formatting requirements except for a recommendation for the last line not to end with a newline.

Class <Event::StageTransition>
------------------------------

Emitted each time suite stage is changed.

### Attributes

  * `$.from` – the stage before transition

  * `$.to` – the stage after transition

Class <Event::JobsAwaited>
--------------------------

Emitted when all pending jobs are completed.

Class `Event::Terminate`
------------------------

Is `Event`.

This is the only kind of event which [`Term::Async::Aggregator`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Term/Async/Aggregator.md) role cares about. It tells the event loop to pull any remaining events from the queue and dispatch them immediately. Then it fulfills event's promise.

### Attributes

  * `Promise::Vow $.completed`, required – a promise vow to be kept when event loop finishes processing all remaining events.

Class `Event::Telemetry`
------------------------

Is `Event`

Under development yet.

Class `Event::Plan`
-------------------

Is `Event::Report`

Plan reporting event. Emitted when a suite gets to know the number of tests to be done.

### Attributes

  * `Bool $.skip` – suite is planned for skiping.

  * `UInt:D $.planned`, required - number of tests planned.

Class `Event::Diag`
-------------------

Is `Event::Report`.

Carries a diagnostics message. See `diag` in [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Base.md).

Class `Event::Ok`
-----------------

Is `Event::Test`.

Test passed.

Class `Event::NotOk`
--------------------

Is `Event::Test`.

Test flunked.

Class `Event::Skip`
-------------------

Is `Event::Test`.

Test skipped.

Class `Event::DoneTesting`
--------------------------

Is `Event::Report`.

Emitted when testing is completely done.

Class `Event::BailOut`
----------------------

Is `Event::Report`

Emitted when test suite is about to bail out.

Command event classes `Event::Cmd::*`
-------------------------------------

A bundle of events used internally for commands. See [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Hub.md) and possibly other modules. The set of command events is not standartized and subject for changes.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Manual.md), [`Test::Async::Aggregator`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Aggregator.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Hub.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

