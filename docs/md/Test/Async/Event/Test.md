Class `Event::Test`
===================

Is [`Event::Report`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Event/Report.md).

Base class for events reporting test outcomes.

### Attributes

  * `Str $.todo` – message to use if test is marked as *TODO*.

  * `Str $.flunks` – message to use if test is marked as anticipated failure (see `test-flunks` in [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Base.md).

  * `CallFrame:D $.caller`, required – position in user code where the test was called.

  * `@.child-messages` – messages from child suites. Each entry should be a single line ending with newline.

  * `@.comments` – comments for the test. Normally expected to be reported with `diag`. Not special formatting

  * `@.pre-comments` - similar to the above, but these will preceed the main test message requirements except for a recommendation for the last line not to end with a newline.

SEE ALSO
========

[`Test::Async::Event`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Event.md), [`Test::Async::Event::Report`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Event/Report.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

