NAME
====



`Test::Async::Decl` - declarations for writing new bundles

SYNOPSIS
========



    use Test::Async::Decl;

    unit test-bundle MyBundle;

    method my-tool(...) is test-tool(:name<mytool>, :!skippable, :!readify) {
        ...
    }

DESCRIPTION
===========



This module exports declarations needed to write custom bundles for `Test::Async` framework.

`test-bundle`
-------------

Declares a bundle role backed by [`Test::Async::Metamodel::BundleHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleHOW.md) metaclass.

`test-reporter`
---------------

Declares a bundle role wishing to act as a reporter. Backed by [`Test::Async::Metamodel::ReporterHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/ReporterHOW.md) metaclass. The bundle also consumes [`Test::Async::Reporter`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Reporter.md) role.

`test-hub`
----------

This kind of package creates a hub class which is backed by [`Test::Async::Metamodel::HubHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/HubHOW.md) metaclass. Barely useful for a third-party developer.

`&trait_mod:<is>(Method:D \meth, :$test-tool!)`
-----------------------------------------------

This trait is used to declare a method in a bundle as a test tool:

    method foo(...) is test-tool {
        ...
    }

The method is then exported to user as `&foo` routine. Internally the method is getting wrapped into a code which does necessary preparations for the tool to act as expected. See [`Test::Async::Metamodel::BundleClassHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleClassHOW.md) for more details.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Manual.md), [`Test::Async::Metamodel::BundleHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleHOW.md), [`Test::Async::Metamodel::BundleClassHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/BundleClassHOW.md), [`Test::Async::Metamodel::HubHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/HubHOW.md), [`Test::Async::Metamodel::ReporterHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Metamodel/ReporterHOW.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

