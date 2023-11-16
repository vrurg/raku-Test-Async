# Class `Test::Async::Event::Terminate`

Is [`Test::Async::Event`](../Event.md)

This is the only kind of event which [`Term::Async::Aggregator`](https://raku.land/?q=Term::Async::Aggregator) role cares about. It tells the event loop to pull any remaining events from the queue and dispatch them immediately. Then it fulfills event's promise.

## Attributes

  - `Promise::Vow $.completed`, required – a promise vow to be kept when event loop finishes processing all remaining events.

# SEE ALSO

  - [`Test::Async::Event`](../Event.md)

  - [`INDEX`](../../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
