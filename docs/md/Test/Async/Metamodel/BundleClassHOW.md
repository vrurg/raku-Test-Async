NAME
====



`Test::Async::Metamodel::BundleClassHOW` - metaclass backing custom bundle classes.

DESCRIPTION
===========



This class purpose is to ensure that test tool methods are wrapped into common boilerplate. The boilerplate does the following:

  * determines calling context to make sure any error reported points at user code where the test tool is invoked. As a result it sets `tool-caller` and `caller-ctx` attributes of the current suite object.

  * validates if current suite stage allows test tool invokation

  * tries to transition the suite into `TSInProgress` stage if tool method object has `$.readify` set (see [`Test::Async::TestTool`](../TestTool.md)

  * emits `Event::Skip` if tool method has its `$.skippable` set and suite's `$.skip-message` is defined.

  * otherwise invokes the original test tool method code.

Wrapping doesn't replace the method object itself.

If test tool method object has its `wrappable` attribute set to *False* then wrapping doesn't take place. In this case the method must take care of all necessary preparations itself. See implementation of `subtest` by [`Test::Async::Base`](../Base.md) for example.

SEE ALSO
========

[`Test::Async::Manual`](../Manual.md), [`Test::Async::Decl`](../Decl.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

