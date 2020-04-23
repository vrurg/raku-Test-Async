NAME
====



`Test::Async::Utils` - `Test::Async` utilities

EXPORTED ENUMS
==============

`TestMode`
----------

Suite mode of operation:

  * `TMSequential` - all child suites are invoked sequentially as appear in the code

  * `TMAsync` – child suites are invoked asynchronously as appear in the code

  * `TMRandom` - child suites are invoked in random order after the suite code is done

`TestStage`
-----------

Suite lifecycle stages: `TSInitializing`, `TSInProgress`, `TSFinishing`, `TSFinished`, `TSDismissed`.

`TestResult`
------------

Test outcome codes: `TRPassed`, `TRFailed`, `TRSkipped`

EXPORTED ROUTINES
=================

`test-result(Bool $cond, Associative :$fail, Associative :$success --` Test::Async::Result)>
--------------------------------------------------------------------------------------------

Creates a [`Test::Async::Result`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Result.md) object using the provided parameters. `$fail` and `$success` are shortcut names for corresponding `-profile` attributes of `Test::Async::Result` class. Note that prior to storing the profiles in the object all values of the first-level keys are getting de-containerized to get any [`Positional`](https://docs.raku.org/type/Positional) attributes of `Event` objects initialized properly.

`stringify(Mu \obj --` Str:D)>
------------------------------

Tries to stringify the `obj` in the most appropriate way. Use it to unify the look of test comments.

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

