CLASS
=====

`Test::Async::Hub::TollCallerCtx` - call location record

DESCRIPTION
===========



Keeps information about where a tool was invoked and what is the role of the invocation.

ATTRIBUTES
==========



### [`CallFrame:D`](https://docs.raku.org/type/CallFrame) `$.frame`

Required. [`CallFrame`](https://docs.raku.org/type/CallFrame) of where the tool/suite was invoked. Note that this would not necessarily point at the immediate caller. See [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.3/docs/md/Test/Async/Manual.md) Call Location And Anchoring section for more information.

### [`Stash:D`](https://docs.raku.org/type/Stash) | [`PseudoStash:D`](https://docs.raku.org/type/PseudoStash) `$.stash`

Required. `.WHO` of the `$.frame` location namespace.

### [`Bool`](https://docs.raku.org/type/Bool) `$.anchored`

Defines whether the location record is an anchored one. See the corresponding section in [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.3/docs/md/Test/Async/Manual.md).

SEE ALSO
========

[`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.3/docs/md/Test/Async.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.3/docs/md/Test/Async/Hub.md), [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.3/docs/md/Test/Async/Manual.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

