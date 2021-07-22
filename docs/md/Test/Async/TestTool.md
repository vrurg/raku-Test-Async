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

[`Bool:D`](https://docs.raku.org/type/Bool) `$.readify`
-------------------------------------------------------

This flag is indicating if test tool must cause it's suite object to transition from `TSInitializing` stage.

[`Bool:D`](https://docs.raku.org/type/Bool) `$.skippable`
---------------------------------------------------------

This flag indicates that this test tool could be skipped. A typical example of a non-skippable tool is the `skip` itself, or `todo` tool family. The importance of this nuance stems from the fact that when `skip-remaining` tool is in effect the wrapper of a test tool code detects this situation and emits a skip event instantly without actually invoking the tool method. Without `$.skippable` reset to *False* a line like:

    skip "for a reason", 3;

would result in a single skip event which is counted as a test run. Our plan will fail because of 2 missing skip events.

[`Bool:D`](https://docs.raku.org/type/Bool) `$.wrappable`
---------------------------------------------------------

Resetting this flag to *False* would result in test tool method would be left intact by [`Test::Async::Metamodel::BundleClassHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.902/docs/md/Test/Async/Metamodel/BundleClassHOW.md).

[`Bool:D`](https://docs.raku.org/type/Bool) `$.anchoring`
---------------------------------------------------------

Marks a test tool as an *anchoring* one. See [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.902/docs/md/Test/Async/Manual.md) Call Location And Anchoring section for more details.

*False* by default.

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

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.902/docs/md/Test/Async/Manual.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.902/docs/md/Test/Async/Decl.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

