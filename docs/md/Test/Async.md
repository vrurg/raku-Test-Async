NAME
====

`Test::Async` - base module of the framework

SYNOPSIS
========

    use Test::Async;
    plan 1;
    pass "Hello World!";
    done-testing;

DESCRIPTION
===========

The module setups testing evironment for a test suite. It is intended to be used in a script implementing the suite but is not recommended for a module. See [`Test::Async::CookBook`](Async/CookBook.md) for more details.

Exports
-------

The module re-exports all symbols found in a test bundle `EXPORT::DEFAULT` package.

Also exports:

### `test-suite`

Return the test suite which is actual for the current context. The suite is looked up either in `$*TEST-SUITE` or via `Test::Async::Hub` `top-suite` method.

### Test Tools

The module exports all test tools it finds in the top suite object. See [`Test::Async::Manual`](Async/Manual.md) for more details.

SEE ALSO
========

[`Test::Async::Manual`](Async/Manual.md), [`Test::Async::CookBook`](Async/CookBook.md), [`Test::Async::Base`](Async/Base.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

