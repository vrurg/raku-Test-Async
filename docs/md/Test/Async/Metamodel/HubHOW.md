NAME
====



`Test::Async::Metamodel::HubHOW` - metaclass backing Hub/Suite classes.

DESCRIPTION
===========



This class acts as a registry for test bundle roles, and as a construction yard for the custom `Test::Async::Suite` class.

methods
=======

`register-bundle(Mu \bundle-role)`

Registers bundle role for later suite class construction.

method
======

`construct-suite(\hub-class --` Test::Async::Suite:U)>

Returns a custom `Test::Async::Suite` class based on all test bundles registered. The construction happens only once, all consequent calls to the method get the same suite type object.

Normally this method is to be invoked on the hub class: `Test::Async::Hub.^construct-suite`.

method
======

`suite-class(\hub-class)`

Convenience shortcut to `construct-suite`

method
======

`suite(\obj)`

Returns *True* if suite class has been constructed already.

method
======

`bundles()`

Returns a list of registered bundles.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Manual.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Decl.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

