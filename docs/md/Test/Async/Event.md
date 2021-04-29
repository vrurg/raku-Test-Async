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



General information about `Test::Async` event management can be found in [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Manual.md).

Events are objects of classes derived from `Event` class. This module provides support for `Test::Async` core. In general, all event classes can be conventionally split into the following groups:

  * *informative* – events signalling about some state changes. Like, for example, suite termination.

  * *reporting* - events bearing a message to be reported to user.

  * *commands* – those which tell the core to perform an action.

  * *tests* – outcomes of individual test tools.

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

EVENT SUBCLASSES
================

  * [`Event::BailOut`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/BailOut.md)

  * [`Event::Command`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Command.md)

  * [`Event::Diag`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Diag.md)

  * [`Event::DoneTesting`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/DoneTesting.md)

  * [`Event::JobsAwaited`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/JobsAwaited.md)

  * [`Event::NotOk`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/NotOk.md)

  * [`Event::Ok`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Ok.md)

  * [`Event::Plan`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Plan.md)

  * [`Event::Report`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Report.md)

  * [`Event::Skip`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Skip.md)

  * [`Event::StageTransition`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/StageTransition.md)

  * [`Event::Telemetry`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Telemetry.md)

  * [`Event::Terminate`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Terminate.md)

  * [`Event::Test`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Event/Test.md)

Command event classes `Event::Cmd::*`
-------------------------------------

A bundle of events used internally for commands. See [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Hub.md) and possibly other modules. The set of command events is not standartized and subject for changes.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Manual.md), [`Test::Async::Aggregator`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Aggregator.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Hub.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

