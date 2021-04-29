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

Profiles to be used to create a new `Event::Test` object. Depending on `$.cond` value either `success-` or `fail-profile` is used. The most typical use of this is to add comments explaining the test outcome.

A profile attribute can be made lazy if set to a code object:

    my $tr = test-result($condition, fail => -> { comments => self.expected-got($expected, $got) });

In this case `event-profile` method will invoke the code and use the return value as profile itself. This improves performance in cases when profile keys are set using some rather heavy code (like the `expected-got` method in the example above) but eventually might not even be used after all.

METHODS
=======



`event-profile(--` Hash:D)>
---------------------------

Returns a profile in accordance to `$.cond` value.

The profile capture is built the following way:

  * if corresponding profile attribute is code then the code is invoked and return value is used

  * profile is coerced into a hash

SEE ALSO
========

`test-result` routine from [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.1.901/docs/md/Test/Async/Utils.md).

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

