PREFACE
=======

This document provides general information about `Test::Async`. Technical details are provided in corresponding modules.

General test framework use information can be found in the documentation of Raku's standard [Test suite](https://docs.raku.org/type/Test). [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Base.md) provides information about differences and additions between the standard framework and `Test::Async`.

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

A module or a role implementing a set of test tools or extending/modifying the core functionality. A bundle providing the default set of tools is included into the framework and implemented by [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Base.md).

### *Reporter*

A test bundle which provides reporting capabilities. For example, [`Test::Async::Reporter::TAP`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Reporter/TAP.md) implements TAP output.

### *Test tool*

This is a routine provided by a bundle to test a condition. Typical and commonly known *test tools* are `pass`, `flunk`, `ok`, `nok`, etc.

ARCHITECTURE
============

The framework is built around *test suite* objects driven by events. Suites are organized with parent-child relations with a single topmost suite representing the main test compunit. Child suites are subjects of a job manager control.

A typical workflow consist of the following steps:

  * a test suite is created

  * it's body is executed. Any invoked test tool results in one or couple events sent

  * events are taken care of by a reporter which presents a user with meaningful representation of testing outcomes

  * if a child suite created it is either invoked instantly or postponed for later depending on it's parent suite status

  * when suite is finished `done-testing` is invoked either implicitly or explicitly

Test Suite Creation
-------------------

On startup the framework constructs a custom `Test::Async::Suite` class which incorporates all core functionality and extensions provided by bundles. The following code:

    use Test::Async;
    say test-suite.^mro(:roles).map( *.^shortname ).join(", ")

results in:

    Suit, Base_class, Base, TAP_class, TAP, Reporter, Hub, JobMgr, Aggregator, Any, Mu
    1..0

*Note that `:roles` named parameter is available since Rakudo compiler release 2020.01.*

Next paragraphs are explaining where this output comes from.

Let's start with bundles. One is created with either `test-bundle` or `test-reporter` keyword provided by [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Decl.md) module. For example:

    test-bundle MyBundle {
        method my-test($got, $expected, $message) is test-tool {
            ...
        }
    }

In fact it is nothing else but a role declaration but with two important side effects:

  * the role is backed by [`Test::Async::Metamodel::BundleHOW`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Metamodel/BundleHOW.md) metaclass which subclasses `Metamodel::ParametricRoleHOW`

  * the declaration installs `ENTER` phaser on the compunit it is declared in which auto-registers the bundle with the framework core.

The second item means that this code:

    use MyBundle;
    use Test::Async;
    plan 1;
    my-test pi, 2*pi, "whatever";

would just work. BTW, if one would try to dump parents and role of the suite object, as show above, he would get:

    Suit, MyBundle_class, MyBundle, TAP_class, TAP, Reporter, Hub, JobMgr, Aggregator, Any, Mu

Becase the framework skips loading the default bundle if there is one explicitly requested by a user. Same applies for `TAP` which is the default reporter bundle and which wouldn't be loaded if the user `use`s an alternative.

When all bundles were loaded and registered, time comes for [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async.md) module to actually construct the suite class.

**Note** that this is why [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async.md) must always be `use`d last. No bundle registered post-suite construction would be actually used.

The construction algorithm could roughly be written as:

  * take the `Test::Async::Hub` class as the first and the current parent

  * take bundles in the order they registered and make classes of them

    * class is created as an empty one with bundle role applied

    * the current parent class is added as a parent

    * the new bundle class is set as the current parent

  * a custom `Test::Async::Suite` class created, its only parent is set to the current parent

Putting this into a diagram would give us something like this for the default case:

    .         Suite -> Base_class -> TAP_class -> Hub -> Any -> Mu
    .                  |             |
    . bundle roles:    Base          TAP

See example script: [examples/multi-bundle.raku](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/examples/multi-bundle.raku)

This approach allows custom bundles easily extend the core functionality or even override certain aspects of it. The latter is as simple as overriding parent methods. For example, [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Base.md) module uses this technique to implement `test-flunks` tool. It is doing so by intercepting test events passed in to `send-test` method of [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Hub.md). It is then inverts test's outcome if necessary and does few other adjustments to a new test event profile and passes on the control to the original `send-test` to complete the task.

Job Management
--------------

The asynchronous nature of the framework requires a proper job management subsystem. It is implemented by [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/JobMgr.md) role and [`Test::Async::Job`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Job.md) class representing a single job to be done. The subsystem implements the following concepts:

  * synchronous execution

  * asynchronous (threaded) execution

  * asynchronous job management with limited number of simultaneously executed jobs

  * postponing

A job is [`Code`](https://docs.raku.org/type/Code) instance accompanied with its associated attributes. Code return value is never provided directly but only via a fulfilled [`Promise`](https://docs.raku.org/type/Promise).

The way the manager works is it creates a pool (not a queue) of jobs. The order in which they're executed is defined by the user code invoking them. When a job completes the manager removes it from the pool. Though not directly manager's job, but it provides a possibility to postpone a job. In this case it is placed into a queue from where it could be picked up and invoked any time it is needed. For example, `Test::Async::Hub` is using this to invoke child suites in a random order: jobs for corresponding suites are postponed and when the main code block of the parent suite finishes it takes the postponed queue, shuffles jobs in it and invokes them in the resulting order.

Events
------

    C<Test::Async> framework handles concurrency using event-driven flow control. Each event is an instance of a class
    inheriting from
    L<C<Test::Async::Event>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Event.md> class. Events
    are queued using a L<C<Channel>|https://docs.raku.org/type/Channel> where they're read from by a dedicated thread and
    dispatched for handling by suite object methods. So it makes each suit own at least two threads: first is for tests
    themselves, the other one is for event handling.

       Thread#1 \
                 \
       Thread#2 --> [Event Queue] -> Event Handler Thread
                 /
       Thread#3 /

The approach allows to combine the best of two worlds: speed of asynchronous operations and predictability of sequential code. In particular, it proves to be useful for object state changes like, for example, for collecting messages from child suites ran asynchronously. Because the messages are stashed in an [`Array`](https://docs.raku.org/type/Array) the procedure is prone to race condition bugs. But when the responsibility of updating the array is in hands of a single thread it greatly simplifies the task.

Another advantage of the events is the ease of extending the framework functionality. Look at [`Test::Async::Reporter::TAP`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Reporter/TAP.md), for example. It takes the burden of reporting to user on its 'shoulders' unloading it off the core. And it does so simply by listening to `Event::Test` kind of events. It would be as easy to implement an alternative reporter to get the test results be sent anywhere!

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

  * `skippable` defines whether the tool can be skipped over. For example, `ok` from [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Base.md) is skippable; but `skip` and the family themselves are not, as well as `todo` and few other.

    test-bundle Test::Foo {
        method test-foo(...) is test-tool(:!skippable, :!readify) { ... }
        method test-bar(...) is test-tool { ... }
    }

SEE ALSO
========

[`Test::Async::CookBook`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/CookBook.md), [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Base.md), [`Test::Async::When`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/When.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Hub.md), [`Test::Async::Event`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Event.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Decl.md), [`Test::Async::X`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/X.md), [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Utils.md),

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

