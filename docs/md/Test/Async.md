# NAME

`Test::Async` - base module of the framework

# SYNOPSIS

``` raku
use Test::Async;
plan 1;
pass "Hello World!";
done-testing
```

# DESCRIPTION

The module setups testing evironment for a test suite. It is intended to be used in a script implementing the suite but is not recommended for a module. See [`Test::Async::CookBook`](Async/CookBook.md) for more details.

## Exports

The module re-exports all symbols found in a test bundle `EXPORT::DEFAULT` package.

Also exports:

### `test-suite`

Return the test suite which is actual for the current context. The suite is looked up either in `$*TEST-SUITE` or via `Test::Async::Hub` `top-suite` method.

### `is test-assertion` or `is test-tool`

A quick way to turn a `routine` into test tool. This means, in particular, that for test tools, invoked from within the routine, any error would be reported as if it is the test assertions flunked. For example, for the following test suite:

``` 
 1: use Test::Async;
 2: sub flunk-me(Str:D $message) is test-assertion {
 3:    subtest $message, :hidden, {
 4:        pass "oki";
 5:        flunk "I'm intentionally bad"
 6:    }
 7: }
 8: test-flunks "we need to see where it flunks";
 9: subtest "Flunking" => {
10:     flunk-me "need to.";
11: }
```

The output would contain something like:

``` 
    # Failed test 'need to.'
    # at ...test-suite-path... line 10
```

The above example also uses the recommended practive of using a test assertion where, whenever it is calling 2 or more test tools, a `:hidden` `subtest` would be wrapping around them in order to create common context.

### Test Tools

The module exports all test tools it finds in the top suite object. See [`Test::Async::Manual`](Async/Manual.md) for more details.

# SEE ALSO

  - [`Test::Async::Manual`](Async/Manual.md)

  - [`Test::Async::CookBook`](Async/CookBook.md)

  - [`Test::Async::Base`](Async/Base.md)

  - [`ChangeLog`](../../../ChangeLog.md)

  - [`INDEX`](../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../LICENSE) file in this distribution.
