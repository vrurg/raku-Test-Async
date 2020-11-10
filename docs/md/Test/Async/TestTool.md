NAME
====



`Test::Async::TestTool` - role consumed by test tool methods

DESCRIPTION
===========



This role is applied by `test-tool` trait to a test tool method.

ATTRIBUTES
==========



`$.tool-name`
-------------

Contains the name which must be used for exporting a test tool routine. Makes sense if method must be named differently from what is provided for the user.

`Bool:D $.readify`
------------------

This flag is indicating if test tool must cause it's suite object to transition from `TSInitializing` stage.

`Bool:D $.skippable`
--------------------

This flag indicates that this test tool could be skipped. A typical example of a non-skippable tool is the `skip` itself, or `todo` tool family. The importance of this nuance stems from the fact that when `skip-remaining` tool is in effect the wrapper of a test tool code detects this situation and emits a skip event instantly without actually invoking the tool method. Without `$.skippable` reset to *False* a line like:

    skip "for a reason", 3;

would result in a single skip event which is counted as a test run. Our plan will fail because of 2 missing skip events.

`Bool:D $.wrappable`
--------------------

Resetting this flag to *False* would result in test tool method would be left intact by [`Test::Async::Metamodel::BundleClassHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Metamodel/BundleClassHOW.md).

METHODS
=======



`set-tool-name(Str:D $name)`
----------------------------

Sets `$.tool-name`.

`set-readify(Boold:D $readify)`
-------------------------------

Sets `$.readify`

`set-skippable(Bool:D $skippable)`
----------------------------------

Sets `$.skippable`

`set-wrappable(Bool:D $wrappable)`
----------------------------------

Sets `$.wrappable`

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Manual.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.16/docs/md/Test/Async/Decl.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

