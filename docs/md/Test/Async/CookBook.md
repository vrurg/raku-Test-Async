`Test::Async` COOK BOOK
=======================

Non-systematic collection of tips.

Testing A Multithreaded Application
-----------------------------------

One of the biggest reasons pushed me to implement `Test::Async` was a need to test event flow in `Vikna` toolkit. The problem with the standard `Test` framework was the need to invoke test tool from inside a separate thread or even threads causing havoc to the test output when `subtest`s are used. Similar problem could arise for any heavily threaded application where it is not always easy to get hold of the internal states without having direct access to them directly from a thread. Sure, it is technically possible to implement a communication channel which could be used to pass data into the test suit main thread, etc., etc., etc.

Nah, that's not how we do it! How about:

    my $test-app = MyTestApp.new;
    subtest "Threaded testing" => {
        my $suite = test-suite;
        $test-app.set-test-suite: $suite;
        $test-app.test-something-threaded;
    }

and then somewhere in the `MyTestApp` class implementation, which is presumably inherits from the base application class and overrides some of its method for testing, we simply do something like:

    method foo($param) {
        $.test-suite.ok: self.is-param-valid($param), "method foo got correct parameter";
        nextsame
    }

`test-suite` attribute is the suite object implementing our subtest, which has been set with `set-test-suite` method.

Does it look a bit over-verbose? Ok, there is another way. Our test class could start new threads using core method `start` instead of the standard Raku keyword. Here is what it might look like:

    my $test-app = MyTestApp.new(:test-suite(test-suite));
    subtest "Threaded testing" => {
        $test-app.test-something-threaded;
    }

The code in the `MyTestApp` class can now look like this:

    method new-task(&code) {
        ...; # Whatever else should be done to start a task
        $.test-suite.start: &code
    }
    method test-something-threaded {
        self.new-task: { self.testing-task }
    }

Though it now looks even more verbose than the previous example, we should remember that some kind of boilerplate code would be needed anyway and our first example still have it around. It's just nor relevant and thus not included here.

Back to the matter now. Eventually, this is what our `foo` method would look like now:

    use Test::Async;
    ...
    method foo($param) {
        ok self.is-param-valid($param), "method foo got correct parameter";
        nextsame
    }

Export From A Bundle
--------------------

Sometimes it might be useful to export a symbol or two from a bundle. The best way to do it is to use `EXPORT::DEFAULT` package defined in your bundle file:

    test-bundle Test::Async::MyBundle {
        ...
    }
    package EXPORT::DEFAULT {
        our sub foo { "exported" }
    }

The reason for doing so is because a user could consume the bundle using [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async.md) parameters:

    use Test::Async <MyBundle Base>;
    say foo;

In this case [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async.md) not only will export all found test tool methods but it would also fetch the symbols from `EXPORT::DEFAULT` and re-export them. Apparently, the approach allows direct consuming via `use` statement to work too:

    use Test::Async::MyBundle;
    use Test::Async::Base;
    use Test::Async;
    say foo;

SEE ALSO
========

[`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async.md), [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Manual.md)

