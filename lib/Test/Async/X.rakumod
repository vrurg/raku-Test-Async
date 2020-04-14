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
}
