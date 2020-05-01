NAME
====

Test::Async - asynchronous, thread-sage testing

SYNOPSYS
========

    use Test::Async;

    plan 2, :parallel;
    subtest "Async 1" => {
        plan 1;
        pass "a test";
    }
    subtest "Async 2" => {
        plan 1;
        pass "another test";
    }

DESCRIPTION
===========

`Test::Async` provides a framework and a base set of tests tools compatible with the standard Raku `Test` module. But contrary to the standard, `Test::Async` has been developed with two primary goals in mind: concurrency and extensibility.

Here is the key features provided:

  * event-driven, threaded, and OO core

  * easy development of 3rd party test bundles

  * asynchronous and/or random execution of subtests

  * support of threaded user code

The SYNOPSYS section provides an example where two subtests would be started in parallel, each in its own thread. This allows to achieve two goals: speed up big test suits by splitting them in smaller chunks; and testing testing for possible concurrency problems in tested code.

With

    plan $count, :random;

subtests will be executed in random order. In this mode it is possible to catch another class of errors caused by code being dependent on the order execution.

It is also possible to combine both *parallel* and *random* modes of operation.

READ MORE
=========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.9/docs/md/Test/Async/Manual.md), [`Test::Async::CookBook`](`Test::Async::CookBook`), [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.9/docs/md/Test/Async.md), [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.9/docs/md/Test/Async/Base.md)

