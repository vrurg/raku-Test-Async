Class `Event::Test`
===================

Is [`Event::Report`](Report.md).

Base class for events reporting test outcomes.

### Attributes

  * `Str $.todo` – message to use if test is marked as *TODO*.

  * `Str $.flunks` – message to use if test is marked as anticipated failure (see `test-flunks` in [`Test::Async::Base`](../Base.md).

  * `CallFrame:D $.caller`, required – position in user code where the test was called.

  * `@.child-messages` – messages from child suites. Each entry should be a single line ending with newline.

  * `@.comments` – comments for the test. Normally expected to be reported with `diag`. Not special formatting

  * `@.pre-comments` - similar to the above, but these will preceed the main test message requirements except for a recommendation for the last line not to end with a newline.

SEE ALSO
========

[`Test::Async::Event`](../Event.md), [`Test::Async::Event::Report`](Report.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

