NAME
====



`Test::Async::Base` – this test bundle contains all the base test tools

SYNOPSIS
========



    use Test::Async::Base;
    use Test::Async;
    plan 1;
    pass "Hello world!";
    done-testing

DESCRIPTION
===========



This bundle is supposed to provide same test tools, as the standard Raku [`Test`](https://docs.raku.org/type/Test). So that

    use Test::Async;
    plan ...;
    ...; # Do tests
    done-testing

would be the same as:

    use Test;
    plan ...;
    ...; # Do tests
    done-testing

For this reason this document only tells about differences between the two.

Test tools resulting in either *ok* or *not ok* messages return either *True* or *False* depending on test outcome. `skip` always considered to be successful and thus returns *True*.

ATTRIBUTES
==========



`Str:D $.FLUNK-message`
-----------------------

The message set with `test-flunks`.

`Numeric:D $.FLUNK-count`
-------------------------

Number of tests expected to flunk. Reduces with each next test completing.

See `take-FLUNK`.

METHODS
=======



`take-FLUNK(--` Str)>
---------------------

If `test-flunks` is in effect then method returns its message and decreases `$.FLUNK-count`.

`multi expected-got(Str:D $expected, Str:D $got, Str :$exp-sfx, Str :$got-sfx --` Str)>
---------------------------------------------------------------------------------------

`multi expected-got($expected, $got, :$gist, :$quote, *%c)`
-----------------------------------------------------------

Method produces standardized *"expected ... but got ..."* messages.

The second candidate is used for non-string values. It stringifies them using [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Utils.md) `stringify` routine and then passes over to the first candidate for formatting alongside with named parameters captured in `%c`.

Named parameters:

  * `:$exp-sfx` - suffix for "expected", a string which will be inserted after it.

  * `:$got-sfx` – suffix for "got"

  * `:$gist` - enforces use of method `gist` to stringify values

  * `:$quote` - enforces use of quotes around the stringified values

`cmd-settestflunk`
------------------

Handler for `Event::Cmd::SetTestFlunk` defined by this bundle.

TEST TOOLS
==========

`diag +@msg`
------------

Unlike the standard [`Test`](https://docs.raku.org/type/Test) `diag`, accepts a list too allowing similar usage as with `say` and `note`.

`skip-remaining($message, Bool :$global?)`
------------------------------------------

Skips all remaining tests in current suite. If `$global` is set then it's the same as invoking `skip-remaining` on all suite parents, including the topmost suite.

`todo-remaining(Str:D $message)`
--------------------------------

Mark all remaining tests of the current suite as *TODO*.

`multi subtest(Pair $what, Bool:D :$async=False, Bool:D :$instant=False, *%plan)`
---------------------------------------------------------------------------------

`multi subtest(Str:D $message, Callable:D \code, Bool:D :$async=False, Bool:D :$instant=False, *%plan)`
-------------------------------------------------------------------------------------------------------

`multi subtest(Callable:D \code, Bool:D :$async=False, Bool:D :$instant=False, *%plan)`
---------------------------------------------------------------------------------------

The default `subtest` behaviour is no different from the one in [`Test`](https://docs.raku.org/type/Test). The difference is that our `subtest` could be invoked:

  * asynchronously

  * in random order with other `subtest`s of the same nesting level

  * randomly and asynchronously at the same time

The asynchronous invocation means that a `subtest` will be run in a new dedicated thread. The random invocation means that `subtest` invocation is postponed until the suite code ends. Then all postponed subtests will be pulled and invoked in a random order.

It is possible to combine both async and random modes which might add even more stress to the code tested.

*Some more information about `Test::Async` job management can be found in [`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Manual.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Hub.md), [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/JobMgr.md)*

The particular mode of operation is defined either by `plan` keys `parallel` or `random`, or by subtest named parameters `async` or `instant`. The named parameters take precedence over plan parameters:

  * if `instant` is set then `plan`'s `random` is ignored

  * if `async` is set then `plan`'s `parallel` is ignored

For example, let's assume that our current suite is configured for random execution of subtest. Then

    subtest "foo", :instant, {
        ...
    }

would result in the `subtest` be invoked right away, where it's declaration is encountered, without postponing. Similarly, if `parallel` plan parameter is in effect, `:instant` will overrule it so it will run right here, right now!

Adding `:async` named parameter too will invoke the subtest instantly and asynchronously. And this also means that a subtest invoked this way won't be counted as a job by [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/JobMgr.md). In other words, we treat `:instant` as: *bypass any queue, just do it here and now!*

Another edge case is using `:async` with `random`. In this case the subtest will be postponed. But when time to invoke subtests comes this particular one will get his dedicated thread no matter what `parallel` is set to.

Any other named parameters passed to a `subtest` are treated as plan keys.

Subset topic variable is set to the backing suite object. For example, this is an excerpt from *t/060-subtest.t*:

    subtest "subtest topic" => {
        .plan: 1;
        .cmp-ok: $_, '===', test-suite, "topic is set to the test suite object";
    }

The example is the recommended mode of operation when a subtest is invoked in a module. In other words, the above example could be written as:

    Test::Async::Hub.test-suite.subtest "subtest topic" => {
        .plan: 1;
        .cmp-ok: $_, '===', test-suite, "topic is set to the test suite object";
    }

and this is the way it must be used in a module. See [`Test::Async`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async.md) and [`Test::Async::CookBook`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/CookBook.md) for more details.

`mutli is-run(Str() $code, %params, Str:D $message = "")`
---------------------------------------------------------

`multi is-run(Str() $code, Str:D $message = "", *%params)`
----------------------------------------------------------

This test tool is not provided by the standard [`Test`](https://docs.raku.org/type/Test) framework, but in slightly different forms it is defined in helper modules included in [Rakudo](https://github.com/rakudo/rakudo/blob/e5ecdc4382d2739a701be7956fad52e897936fea/t/packages/Test/Helpers.pm6#L17) and [roast](https://github.com/Raku/roast/blob/7033b07bbbb54a301b3bfd1253e30c5e7cebdfab/packages/Test-Helpers/lib/Test/Util.pm6#L107) tests.

`is-run` tests `$code` by executing it in a child compiler process. In a way, it is like doining:

    # echo "$code" | rakudo -

Takes the following named parameters (`%params` from the first candidate is passed to the second candidate as a capture):

  * `:$in` – data to be sent to the compiler input

  * `:@compiler-args` – command line arguments for the compiler process

  * `:@args` - command line arguments for `$code`

  * `:$out?` – expected standard output

  * `:$err?` – expected error output

  * `:$exitcode = 0` – expected process exit code.

`multi test-flunks(Str:D $message, Bool :$remaining?)`
------------------------------------------------------

`multi test-flunks($count)`
---------------------------

`multi test-flunks(Str $message, $count)`
-----------------------------------------

This test tool informs the bundle that the following tests are expected to flunk and this is exactly what we expect of them to do! Or we can say that it inverts next `$count` tests results. It can be considered as a meta-tool as it operates over other test tools.

The primary purpose is to allow testing other test tools. For example, test *t/080-is-approx.t* uses it to make sure that tests are failing when they have to fail:

    test-flunks 2;
    is-approx 5, 6;
    is-approx 5, 6, 'test desc three';

Setting `$count` to [`Inf`](https://docs.raku.org/type/Inf) is the same as using `:remaining` named parameter and means: all remaining tests in the current suite are expected to flunk.

SEE
===

ALSO

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Manual.md), [`Test::Async::Decl`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Decl.md), [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Utils.md), [`Test::Async::Event`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.7/docs/md/Test/Async/Event.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

