# NAME

`Test::Async::Base` – this test bundle contains all the base test tools

# SYNOPSIS

``` raku
use Test::Async::Base;
use Test::Async;
plan 1;
pass "Hello world!";
done-testing
```

# DESCRIPTION

This bundle is supposed to provide same test tools, as the standard Raku [`Test`](https://docs.raku.org/type/Test). So that

``` raku
use Test::Async;
plan ... ;
... ;
done-testing
```

would be the same as:

``` raku
use Test;
plan ... ;
... ;
done-testing
```

For this reason this document only tells about differences between the two.

Test tools resulting in either *ok* or *not ok* messages return either *True* or *False* depending on test outcome. `skip` always considered to be successful and thus returns *True*.

# ATTRIBUTES

## `Str:D $.FLUNK-message`

The message set with `test-flunks`.

## `Numeric:D $.FLUNK-count`

Number of tests expected to flunk. Reduces with each next test completing.

See `take-FLUNK`.

# METHODS

## `take-FLUNK(--` Str)\>

If `test-flunks` is in effect then method returns its message and decreases `$.FLUNK-count`.

## `multi expected-got(Str:D $expected, Str:D $got, Str :$exp-sfx, Str :$got-sfx --` Str)\>

## `multi expected-got($expected, $got, :$gist, :$quote, *%c)`

Method produces standardized *"expected ... but got ..."* messages.

The second candidate is used for non-string values. It stringifies them using [`Test::Async::Utils`](Utils.md) `stringify` routine and then passes over to the first candidate for formatting alongside with named parameters captured in `%c`.

Named parameters:

  - `:$exp-sfx` - suffix for "expected", a string which will be inserted after it.

  - `:$got-sfx` – suffix for "got"

  - `:$gist` - enforces use of method `gist` to stringify values

  - `:$quote` - enforces use of quotes around the stringified values

## `cmd-settestflunk`

Handler for `Event::Cmd::SetTestFlunk` defined by this bundle.

# TEST TOOLS

## `diag +@msg`

Unlike the standard [`Test`](https://docs.raku.org/type/Test) `diag`, accepts a list too allowing similar usage as with `say` and `note`.

## `skip-remaining($message, Bool :$global?)`

Skips all remaining tests in current suite. If `$global` is set then it's the same as invoking `skip-remaining` on all suite parents, including the topmost suite.

## `todo-remaining(Str:D $message)`

Mark all remaining tests of the current suite as *TODO*.

## `multi subtest(Pair $what, Bool:D :$async=False, Bool:D :$instant=False, :$hidden=False, *%plan)`

## `multi subtest(Str:D $message, Callable:D \code, Bool:D :$async=False, Bool:D :$instant=False, :$hidden=False, *%plan)`

## `multi subtest(Callable:D \code, Bool:D :$async=False, Bool:D :$instant=False, :$hidden=False, *%plan)`

`subtest` is a way to logically group a number of tests together. The default `subtest` behaviour is no different from what is described in [`Test`](https://docs.raku.org/type/Test#sub_subtest). But additionally we can invoke it:

  - asynchronously

  - in random order with other `subtest`s of the same nesting level

  - randomly and asynchronously at the same time

A `subtest` could also kind of hide itself behind another test tool.

`subtest` returns a [`Promise`](https://docs.raku.org/type/Promise) kept with *True* or *False* depending on `subtest` pass/flunk status.

### Invocation modes of `subtest`

The asynchronous invocation means that a `subtest` will be run in a new dedicated thread. The random invocation means that `subtest` invocation is postponed until the suite code ends. Then all postponed subtests will be pulled and invoked in a random order.

It is possible to combine both async and random modes which might add even more stress to the code tested.

*Some more information about `Test::Async` job management can be found in [`Test::Async::Manual`](Manual.md), [`Test::Async::Hub`](Hub.md), [`Test::Async::JobMgr`](JobMgr.md)*

The particular mode of operation is defined either by `plan` keys `parallel` or `random`, or by subtest named parameters `async` or `instant`. The named parameters take precedence over plan parameters:

  - if `instant` is set then `plan`'s `random` is ignored

  - if `async` is set then `plan`'s `parallel` is ignored

For example, let's assume that our current suite is configured for random execution of subtest. Then

``` raku
subtest "foo", :instant, {
    ...
}
```

would result in the `subtest` be invoked right away, where it's declaration is encountered, without postponing. Similarly, if `parallel` plan parameter is in effect, `:instant` will overrule it so it will run right here, right now\!

Adding `:async` named parameter too will invoke the subtest instantly and asynchronously. And this also means that a subtest invoked this way won't be counted as a job by [`Test::Async::JobMgr`](JobMgr.md). In other words, we treat `:instant` as: *bypass any queue, just do it here and now\!*

Another edge case is using `:async` with `random`. In this case the subtest will be postponed. But when time to invoke subtests comes this particular one will get his dedicated thread no matter what `parallel` is set to.

Any other named parameters passed to a `subtest` are treated as plan keys.

Subset topic variable is set to the backing suite object. For example, this is an excerpt from *t/060-subtest.t*:

``` raku
subtest "subtest topic" => {
    .plan: 1;
    .cmp-ok: $_, '===', test-suite, "topic is set to the test suite object";
}
```

The example is the recommended mode of operation when a subtest is invoked in a module. In other words, the above example could be written as:

``` raku
Test::Async::Hub.test-suite.subtest "subtest topic" => {
    .plan: 1;
    .cmp-ok: $_, '===', test-suite, "topic is set to the test suite object";
}
```

and this is the way it must be used in a module. See [`Test::Async`](../Async.md) and [`Test::Async::CookBook`](CookBook.md) for more details.

### Hidden `subtest`

`:hidden` named parameter doesn't change how a subtest runs but rather how it reports itself. A hidden subtest pretends to be integral part of test tool method which invoked it. It means two things:

  - flunked test tools called by subtest code won't report their location (file and line) (*implemented by [`Test::Async::Reporter::TAP`](Reporter/TAP.md) and might not be supported by 3rd party reporters*)

  - flunked subtest would report location of the test tool method which invoked it

The primary purpose of this mode is to provide means of implementing compound test tools. I.e. tools which consist of two or more tests which outcomes are to be reported back to the user. The most common implementation of such tool method would look like:

``` raku
method compound-tool(..., Str:D $message) is test-tool {
    subtest $message, :hidden, :instant, :!async, {
        plan 2;
        my ($result1, $result2) = (False, False);
        ...;
        ok $result1, "result1";
        ok $result2, "result2";
    }
}
```

Note that we're using explicit `:instant` and `:!async` modes to prevent possible side effect related to use of `:parallel` and `:random` in parent suite's plan. Besides, it is normal for a user to expect a test tool to be semi-atomic operation being done here and now.

## `cmp-deeply(Mu \got, Mu \expected, Str:D $message)`

This test is similar to `is-deeply` as it compares complex structure in depth. The difference is that `cmp-deeply` traverses deep into the structure is reports any difference found at the point where it is found. For example:

``` raku
my @got      = [1, 2, %( foo =>  Foo.new(:foo('13'), :fubar(11)) )];
my @expected = [1, 2, %( foo =>  Foo.new(:foo(13),   :fubar(12)) )];

cmp-deeply @got, @expected, "class instance deep withing an array";
```

This test would result in a diagnostic message like this:

Which tells us that a difference has been found in an instance of a class (*Object*) located in a key `foo` of an [`Associative`](https://docs.raku.org/type/Associative) which is located in the second index of a [`Positional`](https://docs.raku.org/type/Positional). Differences are reported for each attribute where they are found.

Another difference of this test to `is-deeply` is that it disrespect containerization status and focuses on structure alone.

## `multi is-run(Str() $code, %params, Str:D $message = "")`

## `multi is-run(Str() $code, Str:D $message = "", *%params)`

This test tool is not provided by the standard [`Test`](https://docs.raku.org/type/Test) framework, but in slightly different forms it is defined in helper modules included in [Rakudo](https://github.com/rakudo/rakudo/blob/e5ecdc4382d2739a701be7956fad52e897936fea/t/packages/Test/Helpers.pm6#L17) and [roast](https://github.com/Raku/roast/blob/7033b07bbbb54a301b3bfd1253e30c5e7cebdfab/packages/Test-Helpers/lib/Test/Util.pm6#L107) tests.

`is-run` tests `$code` by executing it in a child compiler process. In a way, it is like doing:

Takes the following named parameters (`%params` from the first candidate is passed to the second candidate as a capture):

  - `:$in` – data to be sent to the compiler input

  - `:$out?` – expected standard output

  - `:%env = %*ENV` - environment to be passed to the child process

  - `:@compiler-args` – command line arguments for the compiler process

  - `:@args` - command line arguments for `$code`

  - `:$err?` – expected error output

  - `:$exitcode = 0` – expected process exit code.

  - `:$timeout` - time in second to wait for the process to complete

## `multi test-flunks(Str:D $message, Bool :$remaining?)`

## `multi test-flunks($count)`

## `multi test-flunks(Str $message, $count)`

This test tool informs the bundle that the following tests are expected to flunk and this is exactly what we expect of them to do\! Or we can say that it inverts next `$count` tests results. It can be considered as a meta-tool as it operates over other test tools.

The primary purpose is to allow testing other test tools. For example, test *t/080-is-approx.t* uses it to make sure that tests are failing when they have to fail:

``` raku
test-flunks 2;
is-approx 5, 6;
is-approx 5, 6, 'test desc three';
```

Setting `$count` to [`Inf`](https://docs.raku.org/type/Inf) is the same as using `:remaining` named parameter and means: all remaining tests in the current suite are expected to flunk.

# SEE ALSO

  - [`Test::Async::Manual`](Manual.md)

  - [`Test::Async::Decl`](Decl.md)

  - [`Test::Async::Utils`](Utils.md)

  - [`Test::Async::Event`](Event.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this d
