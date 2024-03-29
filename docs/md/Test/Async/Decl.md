# NAME

`Test::Async::Decl` - declarations for writing new bundles

# SYNOPSIS

``` raku
use Test::Async::Decl;

unit test-bundle MyBundle;

method my-tool(...) is test-tool(:name<mytool>, :!skippable, :!readify) {
    ...
}
```

# DESCRIPTION

This module exports declarations needed to write custom bundles for `Test::Async` framework.

## `test-bundle`

Declares a bundle role backed by [`Test::Async::Metamodel::BundleHOW`](Metamodel/BundleHOW.md) metaclass.

## `test-reporter`

Declares a bundle role wishing to act as a reporter. Backed by [`Test::Async::Metamodel::ReporterHOW`](Metamodel/ReporterHOW.md) metaclass. The bundle also consumes [`Test::Async::Reporter`](Reporter.md) role.

## `test-hub`

This kind of package creates a hub class which is backed by [`Test::Async::Metamodel::HubHOW`](Metamodel/HubHOW.md) metaclass. Barely useful for a third-party developer.

## `&trait_mod:<is>(Method:D \meth, :$test-tool!)`

This trait is used to declare a method in a bundle as a test tool:

``` raku
method foo(...) is test-tool {
    ...
}
```

The method is then exported to user as `&foo` routine. Internally the method is getting wrapped into a code which does necessary preparations for the tool to act as expected. See [`Test::Async::Metamodel::BundleClassHOW`](Metamodel/BundleClassHOW.md) for more details.

The following named parameters are accepted by the trait:

  - `tool-name` aka `name`

  - `skippable` aka `skip`

  - `readify`

  - `wrappable` aka `wrap`

They correspond to same-named attributes of [`Test::Async::TestTool`](TestTool.md). By default `skippable`, `readify`, and `wrappable` are set to *True*. Thus it rather makes sense to negate them, as shown in the [SYNOPSIS](#SYNOPSIS).

# SEE ALSO

  - [`Test::Async::Manual`](Manual.md)

  - [`Test::Async::Metamodel::BundleHOW`](Metamodel/BundleHOW.md)

  - [`Test::Async::Metamodel::BundleClassHOW`](Metamodel/BundleClassHOW.md)

  - [`Test::Async::Metamodel::HubHOW`](Metamodel/HubHOW.md)

  - [`Test::Async::Metamodel::ReporterHOW`](Metamodel/ReporterHOW.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
