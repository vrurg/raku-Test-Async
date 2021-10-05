NAME
====



`Test::Async::Reporter` - a reporter bundle role

DESCRIPTION
===========



This role is applied to a bundle declared with `test-reporter`. Implies implementations of methods:

  * `report-event(Event:D)` – report an event to user

  * `indent-message(+@message, :$prefix, :$nesting, *% --` Array())> - indent all lines in `@message` using `$prefix` by `$nesting` levels. `@message` is expected to be in normalized form (see `normalize-message` in [`Test::Async::Hub`](Hub.md)).

  * `message-to-console(+@message)` – send `@message` to its final destination.

SEE ALSO
========

[`Test::Async::Manual`](Manual.md), [`Test::Async::Decl`](Decl.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

