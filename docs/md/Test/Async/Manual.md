PREFACE
=======

This document provides general information about `Test::Async`. Technical details are provided in corresponding modules.

General test framework use information can be found in the documentation of Raku's standard [Test suite](https://docs.raku.org/type/Test). [`Test::Async::Base`](Base.md) provides information about differences and additions between the standard framework and `Test::Async`.

INTRODUCTION
============

Terminology
-----------

Throughout `Test::Async` documentation the following terms are to be used:

### *Test suite*

This term can have two meanings:

  * a collection of tests

  * the core object responsible for running the tests

The particular meaning is determined by a context or some other way.

### *Test bundle* or just *bundle*

A module or a role implementing a set of test tools or extending/modifying the core functionality. A bundle providing the default set of tools is included into the framework and implemented by [`Test::Async::Base`](Base.md).

### *Reporter*

A test bundle which provides reporting capabilities. For example, [`Test::Async::Reporter::TAP`](Reporter/TAP.md) implements TAP output.

### *Test tool*

This is a routine provided by a bundle to test a condition. Typical and commonly known *test tools* are `pass`, `flunk`, `ok`, `nok`, etc.

ARCHITECTURE
============

The framework is built around *test suite* objects driven by events. Suites are organized with parent-child relations with a single topmost suite representing the main test compunit. Child suites are subjects of a job manager control.

A typical workflow consist of the following steps:

  * a test suite is created

  * its body is executed. Any invoked test tool results in one or couple events sent

  * events are taken care of by a reporter which presents a user with meaningful representation of testing outcomes

  * if a child suite created it is either invoked instantly or postponed for later depending on its parent suite status

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

Let's start with bundles. One is created with either `test-bundle` or `test-reporter` keyword provided by [`Test::Async::Decl`](Decl.md) module. For example:

    test-bundle MyBundle {
        method my-test($got, $expected, $message) is test-tool {
            ...
        }
    }

In fact it is nothing else but a role declaration but with two important side effects:

  * the role is backed by [`Test::Async::Metamodel::BundleHOW`](Metamodel/BundleHOW.md) metaclass which subclasses `Metamodel::ParametricRoleHOW`

  * the declaration installs `ENTER` phaser on the compunit it is declared in which auto-registers the bundle with the framework core.

The second item means that this code:

    use MyBundle;
    use Test::Async;
    plan 1;
    my-test pi, 2*pi, "whatever";

would just work. BTW, if one would try to dump parents and role of the suite object, as show above, he would get:

    Suit, MyBundle_class, MyBundle, TAP_class, TAP, Reporter, Hub, JobMgr, Aggregator, Any, Mu

Becase the framework skips loading the default bundle if there is one explicitly requested by a user. Same applies for `TAP` which is the default reporter bundle and which wouldn't be loaded if the user `use`s an alternative.

When all bundles were loaded and registered, time comes for [`Test::Async`](../Async.md) module to actually construct the suite class.

**Note** that this is why [`Test::Async`](../Async.md) must always be `use`d last. No bundle registered post-suite construction would be actually used.

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

See example script: [examples/multi-bundle.raku](../../../../examples/multi-bundle.raku)

This approach allows custom bundles easily extend the core functionality or even override certain aspects of it. The latter is as simple as overriding parent methods. For example, [`Test::Async::Base`](Base.md) module uses this technique to implement `test-flunks` tool. It is doing so by intercepting test events passed in to `send-test` method of [`Test::Async::Hub`](Hub.md). It is then inverts test's outcome if necessary and does few other adjustments to a new test event profile and passes on the control to the original `send-test` to complete the task.

Job Management
--------------

The asynchronous nature of the framework requires a proper job management subsystem. It is implemented by [`Test::Async::JobMgr`](JobMgr.md) role and [`Test::Async::Job`](Job.md) class representing a single job to be done. The subsystem implements the following concepts:

  * synchronous execution

  * asynchronous (threaded) execution

  * asynchronous job management with limited number of simultaneously executed jobs

  * postponing

A job is [`Code`](https://docs.raku.org/type/Code) instance accompanied with its associated attributes. Code return value is never provided directly but only via a fulfilled [`Promise`](https://docs.raku.org/type/Promise).

The way the manager works is it creates a pool (not a queue) of jobs. The order in which they're executed is defined by the user code invoking them. When a job completes the manager removes it from the pool. Though not directly manager's job, but it provides a possibility to postpone a job. In this case it is placed into a queue from where it could be picked up and invoked any time it is needed. For example, `Test::Async::Hub` is using this to invoke child suites in a random order: jobs for corresponding suites are postponed and when the main code block of the parent suite finishes it takes the postponed queue, shuffles jobs in it and invokes them in the resulting order.

Events
------

`Test::Async` framework handles concurrency using event-driven flow control. Each event is an instance of a class inheriting from [`Test::Async::Event`](Event.md) class. Events are queued using a [`Channel`](https://docs.raku.org/type/Channel) where they're read from by a dedicated thread and dispatched for handling by suite object methods. So it makes each suit own at least two threads: first is for tests themselves, the other one is for event handling.

    Thread#1 \
              \
    Thread#2 --> [Event Queue] -> Event Handler Thread
              /
    Thread#3 /

The approach allows to combine the best of two worlds: speed of asynchronous operations and predictability of sequential code. In particular, it proves to be useful for object state changes like, for example, for collecting messages from child suites ran asynchronously. Because the messages are stashed in an [`Array`](https://docs.raku.org/type/Array) the procedure is prone to race condition bugs. But when the responsibility of updating the array is in hands of a single thread it greatly simplifies the task.

Another advantage of the events is the ease of extending the framework functionality. Look at [`Test::Async::Reporter::TAP`](Reporter/TAP.md), for example. It takes the burden of reporting to user on its 'shoulders' unloading it off the core. And it does so simply by listening to `Event::Test` kind of events. It would be as easy to implement an alternative reporter to get the test results be sent anywhere!

Suite Plan And Lifecycle
------------------------

Suite has a number of parameters affecting its execution. Those are:

  * number of tests planned

  * are child suites to be invoked in parallel?

  * are child suites to be invoked randomly?

  * should the suite be skipped over altogether?

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

  * `skippable` defines whether the tool can be skipped over. For example, `ok` from [`Test::Async::Base`](Base.md) is skippable; but `skip` and the family themselves are not, as well as `todo` and few other.

    test-bundle Test::Foo {
        method test-foo(...) is test-tool(:!skippable, :!readify) { ... }
        method test-bar(...) is test-tool { ... }
    }

Call Location And Anchoring
---------------------------

Whenever a test fails `Test::Async` tries to provide the most useful information about where exactly the failure happened. For this purpose it keeps track of test tool call location. The information is recorded in a [`Test::Async::Hub::ToolCallerCtx`](Hub/ToolCallerCtx.md) record and stored on a tool call stack which kept in a per-job ([`Test::Async::JobMgr`](JobMgr.md)) dynamic variable.

Normally the location is determined by `locate-tool-caller` method of the [`Test::Async::Hub`](Hub.md) class and points at the exact location of where a tool was used. But sometimes this information may not be really useful. For example, imagine a compound test tool which combines a few checks into a single call. Something like:

    method my-compound-tool(...) is test-tool {
        submethod "compound check", :hidden, {
            my-other-compound-tool ...;
        }
    }
    method my-other-compound-tool(...) is test-tool {
        submethod "other compound check", :hidden, {
            flunk "say, something went wrong";
        }
    }

The problem with the above construct is that even with `:hidden` attribute which makes a subtest to mimic it's callee (the compound test tools in our case), the nested submethod of the *other* tool would report the location where it's enclosing tool is invoked, which is inside of `my-compound-tool`. Considering that most likely both methods are part of a module the location reported wouldn't be really useful for a developer. To solve this kind of a problem `Test::Async` provides a way to declare *anchored* test tools or to manually anchor a location for tools with `:!wrappable` attribute of [`Test::Async::TestTool`](TestTool.md). An anchor is a location which will be used by any nested test tool or a suite for its reports:

    method my-compound-tool(...) is test-tool(:anchor) {
        ...
    }

Now, if the *other* `subtest` doesn't pass then the developer will see the location in their test file or wherever the compound tool was invoked.

See [`Test::Async::Hub`](Hub.md) `anchor` method to use within `:!wrappable` tools.

### Call Context

Another important detail to remember when we consider call location and anchoring are test tools utilizing [`EVAL`](https://docs.raku.org/routine/EVAL) routine. For example, we can mention `eval-lives-ok` from [`Test::Async::Base`](Base.md). By doing something like:

    subtest "Contextual" => {
        plan 3;
        my $bar = pi;
        { # The inner block is needed to prevent $bar from being lowered away by optimizer.
            is $bar, pi, "control test";
            eval-lives-ok q<$bar *= 2>, "evaling test sees a local variable";
            is $bar, pi * 2, "eval changed the local variable";
        }
    }

we expect `$bar` to be available to the eval code because this is our lexical context. And yet, the example above is rather simplistic and `eval-lives-ok` can simply use its `CALLER::` context to function correctly. But what if it is a part of a complex test tool which invokes `eval-lives-ok` somewhere deep down to a call chain. How do it guess the right context then? This is where anchoring comes to help by setting common context for all.

SEE ALSO
========

[`Test::Async::CookBook`](CookBook.md), [`Test::Async::Base`](Base.md), [`Test::Async::When`](When.md), [`Test::Async::Hub`](Hub.md), [`Test::Async::Event`](Event.md), [`Test::Async::Decl`](Decl.md), [`Test::Async::X`](X.md), [`Test::Async::Utils`](Utils.md),

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

