# Class `Test::Async::Event::Plan`

Is [`Test::Async::Event::Report`](Report.md).

Plan reporting event. Emitted when a suite gets to know the number of tests to be done.

## Attributes

  - [`Bool`](https://docs.raku.org/type/Bool) `$.skip` – suite is planned for skiping.

  - [`UInt:D`](https://docs.raku.org/type/UInt) `$.planned`, required - number of tests planned.

# SEE ALSO

  - [`Test::Async::Event`](../Event.md)

  - [`INDEX`](../../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
