`Test::Async` COOK BOOK
=======================

Non-systematic collection of tips.

Don't Use `Test::Async` In A Module
-----------------------------------

... unless you really know what you're doing.

**Note** that this section is not about creating own test bundle.

[`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async.md) itself does some backstage work when imported with `use` or `require`. A part of this work is taking a list of registered bundles, fixing it, and building a [`Map`](https://docs.raku.org/type/Map) of exports out of it. The potential problem hides behind the word *fixing* because what it means is adding [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async/Base.md) into the list of registered bundles if no other bundles is registered yet; and adding [`Test::Async::Reporter::TAP`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async/Reporter/TAP.md) to the list if none of the registered bundles does [`Test::Async::Reporter`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async/Reporter.md) role. Say, if there is a module `Foo` which `use`s `Test::Async`, and there is a suite with a header like this:

    use Foo;
    use MyTests;
    use MyReporter;
    use Test::Async;

Then we will have implicitly registered `Test::Async::Base` and `Test::Async::Reporter::TAP`. While not being a problem most of the time, this could pose a risk in some unforeseen edge cases.

The recommended way is to use `Test::Async::Hub` class `test-suite` method which returns the current test :

    use Test::Async::Hub;
    sub foo {
        my $suite = Test::Async::Hub.test-suite;
        $suite.pass: "that's the way";
    }

Another recommended way is shown in the first example of the next section.

Testing A Multithreaded Application
-----------------------------------

One of the biggest reasons which pushed me to implement `Test::Async` was a need to test event flow in `Vikna` toolkit. The problem with the standard `Test` framework was the need to invoke test tool from inside a separate thread or even threads causing havoc to the test output when `subtest`s are used. Similar problem could arise for any heavily threaded application where it is not always easy to get hold of the internal states without having direct access to them from within of a thread. Sure, it is technically possible to implement a communication channel which could be used to pass data into the test suit main thread, etc., etc., etc.

Nah, that's not how we do it! How about:

    subtest "Threaded testing" => {
        my $test-app = MyTestApp.new( :test-suite(test-suite) );
        $test-app.test-something-threaded;
    }

and then somewhere in the `MyTestApp` class implementation, which is presumably inherits from the base application class and overrides some of its method for testing, we simply do something like:

    method foo($param) {
        $.test-suite.ok: self.is-param-valid($param), "method foo got correct parameter";
        nextsame
    }

`test-suite` attribute in this example is the suite object backing our subtest.

It is also possible not to store the suite object as an attribute. Instead, one could use [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async/JobMgr.md) method `start` to spawn new threads. This approach has two advantages: first, it preserves the suite object, on which the method has been invoked, as the one available via `test-suite`; second, it creates an awaitable job meaning that our subtest won't finish until the job is complete:

    method test-something-threaded {
        for ^10 -> $i {
            Test::Async::Hub.test-suite.start: {
                self.bar($i)
            }
        }
    }
    method bar($i) {
        Test::Async::Hub.test-suite.cmp-ok: $i, "<", 10, "small enough"
    }

}

All outcomes of `cmp-ok` will be reported as part of our `subtest`.

This approach provides more flexibility because it makes it possible to simultaneously test different execution branches of the same object:

    use Test::Async;
    plan 1, :parallel;
    my $test-app = MyTestApp.new;
    subtest "Branch 1" => {
        $test-app.test-something-threaded1;
    }
    subtest "Branch 2" => {
        $test-app.test-something-threaded2;
    }

When both methods `test-something-threaded<N>` are using `test-suite.start` then both subtests will report only related test tool outcomes.

Export From A Bundle
--------------------

Sometimes it might be useful to export a symbol or two from a bundle. The best way to do it is to use `EXPORT::DEFAULT` package defined in your bundle file:

    test-bundle Test::Async::MyBundle {
        ...
    }
    package EXPORT::DEFAULT {
        our sub foo { "exported" }
    }

The reason for doing so is because a user could consume the bundle using [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async.md) parameters:

    use Test::Async <MyBundle Base>;
    say foo;

In this case [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async.md) not only will export all found test tool methods but it would also fetch the symbols from `EXPORT::DEFAULT` and re-export them. Apparently, the approach allows direct consuming via `use` statement to work too:

    use Test::Async::MyBundle;
    use Test::Async::Base;
    use Test::Async;
    say foo;

SEE ALSO
========

[`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async.md), [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.11/docs/md/Test/Async/Manual.md)

