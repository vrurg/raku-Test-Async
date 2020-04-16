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

Exports
-------

### `test-suite`

Return the test suite which is actual for the current context. The suite is looked up either in `$*TEST-SUITE` or via `Test::Async::Hub` `top-suite` method.

### Test Tools

The module export all test tools it finds in the top suite object. See [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/C<Test/Async/Manual).md> for more details.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/C<Test/Async/Manual).md>, [`Test::Async::CookBook`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/C<Test/Async/CookBook).md>

