use v6;
unit package Test::Async;

class Event is export {
    has $.origin = $*TEST-SUITE;
    has Int:D $.id = $++;
    has Instant:D $.time = now;

    method Profile {
        self.^attributes(:all)
            .grep( *.has_accessor )
            .map({
                my \attr-val = .get_value(self);
                # Skip if the attribute hasn't been initialized.
                (.container_descriptor.default === attr-val)            # Attr value is the default
                || (.name.substr(0,1) eq '%' | '@' && !attr-val.elems)  # Empty hash or array
                    ?? Empty
                    !! .name.substr(2) => attr-val
            }).Map
    }
}

class Event::Report is Event {
    has Str:D $.message = "";
}

class Event::Command is Event {
    has Capture:D $.args is required;
}

class Event::Test is Event::Report {
    has Int:D $.test-id is required;
    has Str $.todo;
    has Str $.flunks;
    has $.caller is required;
    has @.child-messages;
    has @.comments;
}

class Event::NOP is Event { }
class Event::Terminate is Event {
    has $.completed is required;
}

class Event::Cmd::Plan is Event::Command {
    has Int:D $!planned is required;
}
class Event::Cmd::SkipRemaining is Event::Command { }
class Event::Cmd::Finalize      is Event::Command { }
class Event::Cmd::SetTODO       is Event::Command { }
class Event::Cmd::SyncEvents    is Event::Command { }
# Add a message into suite output. For a child it might mean collecting the message for postponed reporting.
class Event::Cmd::Message       is Event::Command { }

class Event::Telemetry is Event {
    has Duration:D $.elapsed is required;
}

class Event::Plan is Event::Report {
    has Bool $.skip;
    has UInt:D $.planned is required;
}
class Event::Diag is Event::Report { }
class Event::Ok is Event::Test { }
class Event::NotOk is Event::Test { }
class Event::Skip is Event::Test { }
class Event::DoneTesting is Event::Report { }
class Event::BailOut is Event::Report { }
