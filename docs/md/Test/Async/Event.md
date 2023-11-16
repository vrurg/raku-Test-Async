# NAME

`Test::Async::Event` – collection of standard events

# SYNOPSIS

``` raku
use Test::Async::Event;

test-bundle MyBundle {
    method foo(Str:D $message) is test-tool {
        self.send-test: Event::Ok, :$message
    }
}
```

# DESCRIPTION

General information about `Test::Async` event management can be found in [`Test::Async::Manual`](Manual.md).

Events are objects of classes derived from `Event` class. This module provides support for `Test::Async` core. In general, all event classes can be conventionally split into the following groups:

  - *informative* – events signalling about some state changes. Like, for example, suite termination.

  - *reporting* - events bearing a message to be reported to user.

  - *commands* – those which tell the core to perform an action.

  - *tests* – outcomes of individual test tools.

## Class `Event`

The base event class.

### Attributes

  - `$.origin` – event originating object. Defaults to the current test suite object.

  - `Int:D $.id` – event id, a sequential number.

  - `Instant:D $.time` – the moment when event object was created.

### Methods

  - `Profile` – returns a [`Map`](https://docs.raku.org/type/Map) suitable for passing to an event constructor. The method collects all changed public attributes of an object.

  - `gist`, `Str` – stringify event object for reporting.

# EVENT SUBCLASSES

  - [`Test::Async::Event::BailOut`](Event/BailOut.md)

  - [`Test::Async::Event::Command`](Event/Command.md)

  - [`Test::Async::Event::Diag`](Event/Diag.md)

  - [`Test::Async::Event::DoneTesting`](Event/DoneTesting.md)

  - [`Test::Async::Event::JobsAwaited`](Event/JobsAwaited.md)

  - [`Test::Async::Event::NotOk`](Event/NotOk.md)

  - [`Test::Async::Event::Ok`](Event/Ok.md)

  - [`Test::Async::Event::Plan`](Event/Plan.md)

  - [`Test::Async::Event::Report`](Event/Report.md)

  - [`Test::Async::Event::Skip`](Event/Skip.md)

  - [`Test::Async::Event::StageTransition`](Event/StageTransition.md)

  - [`Test::Async::Event::Telemetry`](Event/Telemetry.md)

  - [`Test::Async::Event::Terminate`](Event/Terminate.md)

  - [`Test::Async::Event::Test`](Event/Test.md)

## Command event classes `Event::Cmd::*`

A bundle of events used internally for commands. See [`Test::Async::Hub`](Hub.md) and possibly other modules. The set of command events is not standartized and subject for changes.

# SEE ALSO

  - [`Test::Async::Manual`](Manual.md)

  - [`Test::Async::Aggregator`](Aggregator.md)

  - [`Test::Async::Hub`](Hub.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in th
