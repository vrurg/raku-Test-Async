PREFACE
=======

This document provides general information about `Test::Async`. Technical details are provided in corresponding modules.

General test framework use information can be found in the documentation of Raku's standard [Test suite](https://docs.raku.org/type/Test). [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Base.md) provides information about differences and additions between the standard framework and `Test::Async`.

INTRODUCTION
============

Terminology
-----------

Throughout documentation the following terms are to be used:

### *Test suite*

This term can have two meanings:

  * a collection of tests

  * the core object responsible for running the tests

The particular meaning is determined by a context or some other way.

### *Test bundle* or just *bundle*

A module or a class implementing a set of test tools or extending/modifying the core functionality. A bundle providing the default set of tools is included into the core and implemented by [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Base.md).

### *Reporter*

A test bundle which provides reporting capabilities. For example, [`Test::Async::Reporter::TAP`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Reporter/TAP.md) implements TAP output.

### *Test tool*

This is a routine provided by a bundle to test a condition. Typical and commonly known *test tools* are `pass`, `flunk`, `ok`, `nok`, etc.

ARCHITECTURE
============

The core is built around *test suite* objects driven by events. Suites are organized with parent-child relations with a single topmost suite representing the main test compunit. Child suites are subjects of a job manager control.

A typical workflow consist of the following steps:

  * a test suite is created

  * it's body is executed. Any invoked test tool results in one or couple events sent

  * events are taken care of by a reporter which presents a user with meaningful representation of testing outcomes

  * if a child suite created it is either invoked instantly or postponed for later depending on it's parent suite status

  * when suite is finished `done-testing` is invoked either implicitly or explicitly

Test Suite Creation
-------------------

This is the key step to the rest of this framework functionality. Doing something like `test-suite.WHICH.say` in a suite file would result in something like `Test::Async::Suit|140617904553984`. But don't look into the sources, there is no definition of `Test::Async::Suite` class in there! It gets composed dynamically at run time depending on a particular test suite configuration. Here is what happens.

The framework core is based upon `Test::Async::Hub` class. Special keywords `test-bundle` and `test-reporter` are provided to implement extension classes:

    test-bundle MyBundle {
        method my-test($got, $expected, $message) is test-tool {
            ...
        }
    }

When a compunit containing a `test-bundle` or a `test-reporter` declaration is loaded the corresponding extension class is registering itself with the framework. Upon completion of the test suite compilation the framework takes all registered extensions and composes `Test::Async::Suite` class using the following rules:

  * all classes become direct parents of `Test::Async::Suite`

  * `Test::Async::Hub` is always the last parent

  * extension classes are added in the order they were loaded; i.e. the latest loaded becomes the first parent of `Test::Async::Suite` in MRO order. See example [examples/multi-bundle.raku](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/examples/multi-bundle.raku)

`Test::Async::Suite` is then used to create the top-level suite object and all its children.

This approach allows custom bundles easily extend the core functionality or even override certain aspects of it. The latter is as simple as overriding parent methods. For example, `Test::Async::Base` module uses this technique to implement `test-flunks` tool. It is doing so by intercepting test events passed in to `send-test` method of `Test::Async::Hub`. It is then inverts test outcome if necessary and does few other adjustments to a new test event profile and passes on the control to the original `send-test` to complete the task.

It is important to keep in mind that the actual inheritance scheme of `Test::Async::Suite` is:

    Suite -+-> Bundle1
           |
           +-> Bundle2
           |
           +-> Hub

and not `Suite -> Bundle1 -> Bundle2 -> Hub` because this affects how MRO method dispatching works. In the latter case all multi methods would have common `proto` and in many cases it'd be sufficient for a bundle to define a since candidate for, say, event handling and the rest would have taken care of automatically by a parent class. In fact, `Test::Async::Base` requires a `send-test` method candidate with all-capture signature which redelegates to a parent using `nextsame`.

Job Management
--------------

The asynchronous nature of the framework requires a proper job management subsystem. It is implemented by [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/JobMgr.md) role and L`Test::Async::Job`> class representing a single job to be done. The subsystem implements the following concepts:

  * synchronous execution

  * asynchronous (threaded) execution

  * asynchronous job management with limited number of simultaneously executed jobs

  * postponing

A job is [`Code`](https://docs.raku.org/type/Code) instance accompanied with its associated attributes. Code return value is never provided directly but only via a fulfilled [`Promise`](https://docs.raku.org/type/Promise).

The way the manager works is it creates a pool (not a queue) of jobs. The order in which they're executed is defined by the user code invoking them. When a job completes the manager removes it from the pool. Though not directly manager's job, but it provides a possibility to postpone a job. In this case it is placed into a queue from where it could be picked up and invoked any time it is needed. For example, `Test::Async::Hub` is using this to invoke child suites in a random order: jobs for corresponding suites are postponed and when the main code block of the parent suite finishes it takes the postponed queue, shuffles jobs in it and invokes them in the resulting order.

Events
------

Concurrency support in `Test::Async` is implemented event-driven management. Each suite object involves at least two threads. First is running tests, second handles events and is in charge of changing suite object internal status where this is required to prevent race conditions.

    Thread#1 \
              \
    Thread#2 --> [Event Queue] -> Event Handler Thread
              /
    Thread#3 /

The method allows to combine the best of two worlds: speed of asynchronous operations and predictability of sequential code.

Another advantage of the events is the ease of extending the framework functionality. Look at [`Test::Async::Reporter::TAP`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Reporter/TAP.md), for example. It takes the burden of reporting to user on its 'shoulders' unloading it off the core. And it does so simply by listening to `Event::Test` kind of events. It would be as easy to implement an alternative reporter to get the test results be sent anywhere!

Suite Plan And Lifecycle
------------------------

Suite has a number of parameters affecting it's execution. Those are:

  * number of tests planned

  * do child suites are invoked in parallel?

  * do child suites invoked randomly?

  * should the suite be skipped over?

  * does suite tests for a TODO feature?

While executed, the suite passes a few stages:

  * *initialization*

  * *in progress* - tests are being ran

  * *finishing* - any postponed jobs are executed

  * *finished* - testing is done, suite is summing up and possibly reporting the results

  * *dismissed* - all done, suit object can be dropped

The parameters can only be set or changed while suite is being initialized and no test tools can be invoked at and after the *finished* stage.

Worth noting that *finishing* stage is basically same as `in progress` except that it indicates that the time of postponed jobs has come.

Test Tools
----------

A test tool is a method with `test-tool` trait applied. It has two properties:

  * `readify` which defines whether invoking the tool results in suite transition from stage *initializing* into *in progress* 

  * `skippable` defines whether the tool can be skipped over. For example, `ok` from [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Base.md) is skippable; but `skip` and the family themselves are not, as well as `todo` and few other.

SEE ALSO
========

[`Test::Async::CookBook`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/CookBook.md) [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Base.md) [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Hub.md) [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Utils.md)

