PREFACE
=======

This document provides general information about `Test::Async`. Technical details are provided in corresponding modules.

INTRODUCTION
============

Terminology
-----------

Throughout documentation the following terms are to be used:

### *Test suite*

This term can have two meanings:

  * a collection of tests

  * the core object reposnsible for running the tests

The particular meaning is determined by a context or some other way.

### *Test bundle* or just *bundle*

A module or a class implementing a set of test tools or extending/modifying the core functionality. A bundle providing the default set of tools is included into the core and implemented by [`Test::Async::Base`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Base.md).

