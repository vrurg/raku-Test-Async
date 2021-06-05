NAME
====



`Test::Async::X` - collection of `Test::Async` exceptions

DESCRIPTION
===========



All exceptions are based upon `Test::Async::X` class. The class has and requires a single attribute `$.suite` which points at the suite object which thrown the exception. The recommended method `throw` of [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Hub.md) sets the attribute automatically.

EXPORTED EXCEPTIONS
===================

  * `Test::Async::X::AwaitTimeout`

  * `Test::Async::X::AwaitWithPostponed`

  * `Test::Async::X::BadPostEvent`

  * `Test::Async::X::JobInactive`

  * `Test::Async::X::NoJobId`

  * `Test::Async::X::NoToolCaller`

  * `Test::Async::X::PlanRequired`

  * `Test::Async::X::StageTransition`

  * `Test::Async::X::WhenCondition`

  * `Test::Async::X::TransparentWithoutParent`

  * `Test::Async::X::FileOp`

    * `Test::Async::X::FileCreate`

    * `Test::Async::X::FileClose`

    * `Test::Async::X::FileWrite`

    * `Test::Async::X::FileRead`

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Manual.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Hub.md), [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.2/docs/md/Test/Async/Utils.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

