use v6;


module Test::Async::X {
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
            "Timed out awaiting for $!what";
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
