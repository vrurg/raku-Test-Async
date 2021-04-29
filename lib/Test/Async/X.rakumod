use v6;

=begin pod
=NAME

C<Test::Async::X> - collection of C<Test::Async> exceptions

=DESCRIPTION

All exceptions are based upon C<Test::Async::X> class. The class has and requires a single attribute C<$.suite> which
points at the suite object which thrown the exception. The recommended method C<throw> of
L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Hub.md>
sets the attribute automatically.

=head1 EXPORTED EXCEPTIONS

=item C<Test::Async::X::AwaitTimeout>
=item C<Test::Async::X::AwaitWithPostponed>
=item C<Test::Async::X::BadPostEvent>
=item C<Test::Async::X::JobInactive>
=item C<Test::Async::X::NoJobId>
=item C<Test::Async::X::NoToolCaller>
=item C<Test::Async::X::PlanRequired>
=item C<Test::Async::X::StageTransition>
=item C<Test::Async::X::WhenCondition>
=item C<Test::Async::X::TransparentWithoutParent>
=item C<Test::Async::X::FileOp>
=item2 C<Test::Async::X::FileCreate>
=item2 C<Test::Async::X::FileClose>
=item2 C<Test::Async::X::FileWrite>
=item2 C<Test::Async::X::FileRead>

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Hub.md>,
L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.1/docs/md/Test/Async/Utils.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit package Test::Async;

module X is export {
    use Test::Async::Utils;

    class Base is Exception {
        has $.suite is required;
    }

    class BadPostEvent is Base {
        has $.owner is required;
        method message {
            "Event posted from outside of expected event queue owner " ~ $.owner.WHICH
        }
    }

    class StageTransition is Base {
        has TestStage:D $.from is required;
        has TestStage:D $.to is required;
        method message {
            "Illegal suit stage transition from " ~ $!from ~ " to " ~ $!to
        }
    }

    class PlanRequired is Base {
        has Str:D $.op is required;
        method message {
            "A plan is required in order to use $.op"
        }
    }

    class PlanTooLate is Base {
        method message {
            "It is too late to change plan at " ~ $.suite.tool-caller.frame.gist;
        }
    }

    class NoJobId is Base {
        has Int:D $.id is required;
        method message {
            "There is no job #$!id registered in the manager"
        }
    }

    class JobInactive is Base {
        has $.id is required;
        method message {
            "Job #$!id is already inactive"
        }
    }

    class AwaitWithPostponed is Base {
        has $.count is required;
        method message {
            "Cannot await for all jobs untils there're any postponed ones"
        }
    }

    class AwaitTimeout is Base {
        has Str:D $.what is required;
        method message {
            "Timeout awaiting for $!what";
        }
    }

    class WhenCondition is Base {
        has $.cond is required;
        method message {
            "Bad 'when' condition :" ~ $.cond
        }
    }

    role FileOp is Base {
        has Str:D $.fname is required;
        has Str:D $.details is required;
        method action {...}
        method message {
            "Can't " ~ self.action ~ " file '" ~ $!fname ~ "': " ~ $!details
        }
    }

    class FileCreate does FileOp { method action { 'create' } }
    class FileClose  does FileOp { method action { 'close' } }
    class FileWrite  does FileOp { method action { 'write' } }
    class FileRead    does FileOp { method action { 'read' } }

    class TransparentWithoutParent {
        method message {
            "Transparent attribute is set but the suite doesn't have a parent"
        }
    }

    class EmptyToolStack is Base {
        has Str:D $.op is required;
        method message {
            "Operation '" ~ $!op ~ "' attempted on empty tool call stack"
        }
    }

    class NoToolCaller is Base {
        method message {
            "Cannot locate test tool caller"
        }
    }
}
