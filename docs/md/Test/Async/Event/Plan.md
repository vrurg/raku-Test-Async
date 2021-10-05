Class `Event::Plan`
===================

Is [`Event::Report`](Report.md).

Plan reporting event. Emitted when a suite gets to know the number of tests to be done.

Attributes
----------

  * [`Bool`](https://docs.raku.org/type/Bool) `$.skip` – suite is planned for skiping.

  * [`UInt:D`](https://docs.raku.org/type/UInt) `$.planned`, required - number of tests planned.

SEE ALSO
========

[`Test::Async::Event`](../Event.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

