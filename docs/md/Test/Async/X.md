# NAME

`Test::Async::X` - collection of `Test::Async` exceptions

# DESCRIPTION

All exceptions are based upon `Test::Async::X` class. The class has and requires a single attribute `$.suite` which points at the suite object which thrown the exception. The recommended method `throw` of [`Test::Async::Hub`](Hub.md) sets the attribute automatically.

# EXPORTED EXCEPTIONS

  - `Test::Async::X::AwaitTimeout`

  - `Test::Async::X::AwaitWithPostponed`

  - `Test::Async::X::BadPostEvent`

  - `Test::Async::X::JobInactive`

  - `Test::Async::X::NoJobId`

  - `Test::Async::X::NoToolCaller`

  - `Test::Async::X::PlanRequired`

  - `Test::Async::X::StageTransition`

  - `Test::Async::X::WhenCondition`

  - `Test::Async::X::TransparentWithoutParent`

  - `Test::Async::X::FileOp`
    
      - `Test::Async::X::FileCreate`
    
      - `Test::Async::X::FileClose`
    
      - `Test::Async::X::FileWrite`
    
      - `Test::Async::X::FileRead`

# SEE ALSO

  - [`Test::Async::Manual`](Manual.md)

  - [`Test::Async::Hub`](Hub.md)

  - [`Test::Async::Utils`](Utils.md)

  - [`Test::Async`](../Async.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2020-2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
