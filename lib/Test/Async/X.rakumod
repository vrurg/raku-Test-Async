use v6;

=begin pod
=NAME

C<Test::Async::X> - collection of C<Test::Async> exceptions

=DESCRIPTION

All exceptions are based upon C<Test::Async::X> class. The class has and requires a single attribute C<$.suite> which
points at the suite object which thrown the exception. The recommended method C<throw> of
L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.8/docs/md/Test/Async/Hub.md>
sets the attribute automatically.

=head1 EXPORTED EXCEPTIONS

=item C<X::AwaitTimeout>
=item C<X::AwaitWithPostponed>
=item C<X::BadPostEvent>
=item C<X::JobInactive>
=item C<X::NoJobId>
=item C<X::PlanRequired>
=item C<X::StageTransition>

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.8/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.8/docs/md/Test/Async/Hub.md>,
L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.8/docs/md/Test/Async/Utils.md>

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
        has $.caller = $*TEST-CALLER;
        method message {
            "It is too late to change plan at " ~ $!caller.gist;
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
    class FileRed    does FileOp { method action { 'read' } }
}
