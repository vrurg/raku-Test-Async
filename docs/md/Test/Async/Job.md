NAME
====



`Test::Async::Job` - a job record task

DESCRIPTION
===========



Class defines a job entry for [`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/JobMgr.md).

ATTRIBUTES
==========



`Int:D $.id`
------------

Job ID number. Autoincerements.

`Callable:D $.code`
-------------------

User code to be executed.

`Bool $.async`
--------------

If *True* then the job must be executed asynchronously.

`Promise $.promise`
-------------------

Job completion promise. Undefined until the job is invoked. Set to a [`Promise`](https://docs.raku.org/type/Promise) instance as soon as job starts execution and is kept with job code return value.

METHODS
=======



`start(--` Promise:D)>
----------------------

Starts job in a thread.

`invoke(--` Promise:D)>
-----------------------

Starts job instantly in the current thread.

`is-started(--` Bool)>
----------------------

*True* if job has been started.

`is-completed(--` Bool)>
------------------------

*True* if job has completed.

SEE ALSO
========

[`Test::Async::JobMgr`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/JobMgr.md), [`Test::Async::Hub`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Hub.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

