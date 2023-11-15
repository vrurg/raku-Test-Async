# NAME

`Test::Async::Reporter` - a reporter bundle role

# DESCRIPTION

This role is applied to a bundle declared with `test-reporter`. Implies implementations of methods:

  - `report-event(Event:D)` – report an event to user

  - `indent-message(+@message, :$prefix, :$nesting, *% --` Array())\> - indent all lines in `@message` using `$prefix` by `$nesting` levels. `@message` is expected to be in normalized form (see `normalize-message` in [`Test::Async::Hub`](Hub.md)).

  - `message-to-console(+@message)` – send `@message` to its final destination.

# SEE ALSO

  - [`Test::Async::Manual`](Manual.md)

  - [`Test::Async::Decl`](Decl.md)

  - [`Test::Async`](../Async.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distributio
