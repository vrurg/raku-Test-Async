NAME
====



`Test::Async::Result` - test result representation

SYNOPSIS
========



    self.proclaim: test-result(
                        $condition, 
                        fail => {
                            comments => "a comment about the cause of flunk",
                        });

DESCRIPTION
===========



This class represents information about test outcomes.

ATTRIBUTES
==========



`Bool:D $.cond`
---------------

*True* if test is considered success, *False* otherwise. **Note** that a skipped tests is a success.

`$.fail-profile`, `$.success-profile`
-------------------------------------

Profile to be used to create a new `Event::Test` object depending on `$.cond` value either `success-` or `fail-profile` is used. The most typical use of this is to add comments explaining the test outcome.

METHODS
=======



`event-profile()`
-----------------

Returns a profile accordingly to `$.cond`.

SEE ALSO
========

`test-result` routine from [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Utils.md).

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

