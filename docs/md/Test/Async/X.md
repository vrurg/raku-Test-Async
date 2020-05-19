NAME
====



`Test::Async::X` - collection of `Test::Async` exceptions

DESCRIPTION
===========



All exceptions are based upon `Test::Async::X` class. The class has and requires a single attribute `$.suite` which points at the suite object which thrown the exception. The recommended method `throw` of [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Hub.md) sets the attribute automatically.

EXPORTED EXCEPTIONS
===================

  * `X::AwaitTimeout`

  * `X::AwaitWithPostponed`

  * `X::BadPostEvent`

  * `X::JobInactive`

  * `X::NoJobId`

  * `X::PlanRequired`

  * `X::StageTransition`

  * `X::WhenCondition`

  * `X::FileOp`

    * `X::FileCreate`

    * `X::FileClose`

    * `X::FileWrite`

    * `X::FileRead`

  * `X::TransparentWithoutParent`

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Manual.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Hub.md), [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.13/docs/md/Test/Async/Utils.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

