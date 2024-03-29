# NAME

`Test::Async::When` - add `:when` key to plan

# SYNOPSIS

Entire top suite:

``` raku
use Test::Async <When Base>;
plan :when((<release>))
```

Or a subtest only:

``` raku
use Test::Async <When Base>;
subtest "Might be skipped" => {
    plan :when((:all((:any((<release author>)), :module<Optional::Module>))));
    ...
}
}
```

# DESCRIPTION

This bundle extends `plan` with additional parameter `:when` which defines when the suite is to be actually ran. If `when` condition is not fulfilled the suite is skipped. The condition is a nested combination of keys and values:

  - a string value means a name of a testing mode enabled with an environment variable. Simply put, it gets uppercased, appended with *\_TESTING* and the resulting name is checked against `%*ENV`. If the string is already ending with *\_TESTING* it is used as-is.

  - a pair with `env` key tests for a environment variable. The variable name is used as-is, with no manipulations done to it.

  - a pair with `module` key tests if a module with the given name is available

  - a pair with keys `any` or `all` basically means that either any of it subcondition or all of them are to be fulfilled

  - a pair with `none` key means all of its sunconditions must fail.

By default the topmost condition means `any`, so that the following two statements are actually check the same condition:

``` raku
plan :when<release author>;
plan :when(:any<release author>);
```

# SEE ALSO

  - [`Test::Async::Manual`](Manual.md)

  - [`Test::Async`](../Async.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
