NAME
====



`Test::Async::Metamodel::BundleClassHOW` - metaclass backing custom bundle classes.

DESCRIPTION
===========



This class function is to ensure that test tool methods are wrapped into common boilerplate. The boilerplate does the following:

  * determines calling context to make sure any error reported points at user code where the test tool is invoked. As a result it sets two dynamic variables

    * `$*TEST-THROWS-LIKE-CTX` – [`Stash`](https://docs.raku.org/type/Stash) for test tools using EVAL.

    * `$*TEST-CALLER` - [`CallerFrame`](https://docs.raku.org/type/CallerFrame) instance of the frame where the tool is invoked.

  * validates if current suite stage allows test tool invokation

  * tries to transition the suite into `TSInProgress` stage if tool method object has `$.readify` set (see [`Test::Async::TestTool`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/TestTool.md)

  * emits `Event::Skip` if tool method has its `$.skippable` set and suite's `$.skip-message` is defined.

  * otherwise invokes the original test tool method code.

Note that wrapping doesn't replace the method object itself.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Manual.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Decl.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

