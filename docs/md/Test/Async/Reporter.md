NAME
====



`Test::Async::Reporter` - a reporter bundle role

DESCRIPTION
===========



This role is applied to a bundle declared with `test-reporter`. Implies implementations of methods:

  * `report-event(Event:D)` – report an event to user

  * `indent-message(+@message, :$prefix, :$nesting, *% --` Array())> - indent all lines in `@message` using `$prefix` by `$nesting` levels. `@message` is expected to be in normalized form (see `normalize-message` in [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Hub.md)).

  * `message-to-console(+@message)` – send `@message` to its final destination.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Manual.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Decl.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

