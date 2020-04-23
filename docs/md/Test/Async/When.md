NAME
====



`Test::Async::When` - add `:when` key to plan

SYNOPSIS
========



Whole top suite:

    use Test::Async <When Base>;
    plan :when(<release>);

Or a subtest only:

    use Test::Async <When Base>;
    subtest "Might be skipped" => {
        plan :when(
                :all(
                    :any(<release author>),
                    :module<Optional::Module>));
        ...
    }

}

DESCRIPTION
===========



This bundle extends `plan` with additional parameter `:when` which defines when the suite is to be actually ran. If `when` condition is not fulfilled the suite is skipped. The condition is a nested combination of keys and values:

  * a string value means a name of a testing mode enabled with an environment variable

  * a pair with keys `any` or `all` basically means that either any of it subcondition or all of them are to be fulfilled

  * a pair with `module` key tests if a module with the given name is available

By default the topmost condition means `any`, so that the following two statements are actually check the same condition:

    plan :when<release author>;
    plan :when(:any<release author>);

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Manual.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

