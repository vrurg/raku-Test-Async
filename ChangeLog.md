# CHANGELOG

  - **v0.1.17**
    
      - Take care of exceptions that throw on their own when reported
    
      - Fix a test that was freezing if `$RAKUDO_MAX_THREADS` environment variable is set to a too low value

  - **v0.1.16**
    
      - Fix `cmp-deeply` for nominalizables
    
      - Fix `cmp-deeply` for paramterized hashes with non-string keys

  - **v0.1.15**
    
      - Fix `test-assertion` trait when the assertion is used at the top level

  - **v0.1.14**
    
      - Implement `test-assertiion` trait
    
      - Fix `exit` freezing when called within a `subtest`

  - **v0.1.13**
    
      - Fix comparing of undefined attributes

  - **v0.1.12**
    
      - Fix `cmp-deeply` failing while reporting a `Pair`

  - **v0.1.11**
    
      - `isa-ok` reports types only now
    
      - Fix handling of TEST\_JOBS environment variable

  - **v0.1.10**
    
      - Make `cmp-deeply` reports about difference in positionals or associatives more detailed by reporting different sizes or key sets, respectively.

  - **v0.1.9**
    
      - `diag` is now using `**` slurpiness and gistifies its arguments, making it more `say`-alike
    
      - Added `cmp-deeply` test

  - **v0.1.7**
    
      - Make the module play well with independent threads
    
      - Improve warning message for tools invoked after `done-testing`

  - **v0.1.6**
    
      - Fixed a critical bug in slang which was breaking role declarations

  - **v0.1.5**
    
      - Fixed compatibility with Rakudo compiler new-disp implementation

  - **v0.1.4**
    
      - Mostly bug fix release
    
      - Added `:timeout` parameter to `is-run`

  - **v0.1.3**
    
      - Improved handling of exceptions
    
      - Subtests now attempt to report any exception produced by their body rather than bailing out immediately
    
      - New method on Aggregator role: event-queue-active
    
      - A couple of minor fixes

  - **v0.1.2**
    
      - Fixed a rare bug causing `throws-like` to throw itself.

  - **v0.1.1**
    
      - Fixed a tool call stack race condition
    
      - Fixed a todo+subtest race condition and extra todo count consumption

  - **v0.1.0**
    
      - Implemented tool call stack and tool anchoring ([`Test::Async::Manual`](docs/md/Test/Async/Manual.md))
    
      - Added support for pre-comments, or header comments, to [`Test::Async::Event::Test`](docs/md/Test/Async/Event/Test.md)
    
      - Added a header to the output of non-hiddent subtests, similar to [a Rakudo request ticket](https://github.com/rakudo/rakudo/issues/4266)
    
      - Implemented auto-registration for inline `test-bundle` declarations
    
      - Added `abort-testing` tool

# SEE ALSO

  - [`Test::Async`](docs/md/Test/Async.md)

  - [`README`](README.md)

  - [`INDEX`](INDEX.md)
