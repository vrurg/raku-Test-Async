use v6;
unit package Test::Async;

module X is export {
    use Test::Async::Utils;

    class Base is Exception {
        has $.hub is required;
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
}
