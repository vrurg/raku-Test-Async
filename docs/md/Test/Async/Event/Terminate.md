Class `Event::Terminate`
========================

Is [`Event`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Event.md)

This is the only kind of event which [`Term::Async::Aggregator`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Term/Async/Aggregator.md) role cares about. It tells the event loop to pull any remaining events from the queue and dispatch them immediately. Then it fulfills event's promise.

Attributes
----------

  * `Promise::Vow $.completed`, required – a promise vow to be kept when event loop finishes processing all remaining events.

SEE ALSO
========

[`Test::Async::Event`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Event.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

