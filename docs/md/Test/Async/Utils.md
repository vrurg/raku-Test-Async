# NAME `Test::Async::Utils` - `Test::Async` utilities

# EXPORTED ENUMS

## `TestMode`

Suite mode of operation:

  - `TMSequential` - all child suites are invoked sequentially as appear in the code

  - `TMAsync` – child suites are invoked asynchronously as appear in the code

  - `TMRandom` - child suites are invoked in random order after the suite code is done

## `TestStage`

Suite lifecycle stages: `TSInitializing`, `TSInProgress`, `TSFinishing`, `TSFinished`, `TSDismissed`.

## `TestResult`

Test outcome codes: `TRPassed`, `TRFailed`, `TRSkipped`

# EXPORTED ROUTINES

## `test-result(Bool $cond, :$fail, :$success --` Test::Async::Result)\>

Creates a [`Test::Async::Result`](Result.md) object using the provided parameters. `$fail` and `$success` are shortcut names for corresponding `-profile` attributes of `Test::Async::Result` class.

## `stringify(Mu \obj --` Str:D)\>

Tries to stringify the `obj` in the most appropriate way. Use it to unify the look of test comments.

# SEE ALSO

  - [`Test::Async`](../Async.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
