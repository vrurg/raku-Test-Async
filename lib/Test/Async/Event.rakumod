use v6;


unit package Test::Async;

use Test::Async::Utils;

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

    method gist {
        self.^name ~ "#" ~ $!id ~ ": orig='" ~ ($!origin.message // '*no message*') ~ "'"
    }
    method Str { self.gist }
}

class Event::Report is Event {
    has Str:D $.message = "";

    method gist {
        my $pfx =         "           ";
        callsame() ~ "\n" ~ "  message: " ~ (
            $.message.split(/\n/)
                     .map({ $pfx ~ $_ })
                     .join("\n")
        )
    }
}

class Event::Command is Event {
    has Capture:D $.args is required;

    method gist {
        callsame() ~ "\n  args: " ~ $.args.gist
    }
}

class Event::Test is Event::Report {
    has Str $.todo;
    has Str $.flunks;
    has ToolCallerCtx:D $.caller is required;
    has @.pre-comments;
    has @.child-messages;
    has @.comments;
    method new(*%p) {
        # Decont all profile values to get array attributes properly initialized
        nextwith |%p.map({ .key => .value<> }).Map.Capture
    }
}

class Event::Terminate is Event {
    has Promise:D $.terminated .= new;
}

class Event::StageTransition is Event {
    has $.from is required;
    has $.to is required;
    has %.params; # May contain some additional details about the transition
    method gist {
        callsame() ~ " " ~ $.from ~ " -> " ~ $.to
    }
}
class Event::JobsAwaited is Event { }

class Event::Cmd::Plan is Event::Command {
    has Int:D $!planned is required;
}
class Event::Cmd::SkipRemaining is Event::Command { }
class Event::Cmd::Finalize      is Event::Command { }
class Event::Cmd::SetTODO       is Event::Command { }
class Event::Cmd::SyncEvents    is Event::Command { }
# Add a message into suite output. For a child it might mean collecting the message for postponed reporting.
class Event::Cmd::Message       is Event::Command { }
class Event::Cmd::BailOut       is Event::Command { }

class Event::Telemetry is Event {
    has Duration:D $.elapsed is required;
}

class Event::Plan is Event::Report {
    has Bool $.skip;
    has UInt:D $.planned is required;

    method gist {
        callsame() ~ "\n  planned: " ~ $.planned;
    }
}
class Event::Diag is Event::Report { }
class Event::Ok is Event::Test { }
class Event::NotOk is Event::Test { }
class Event::Skip is Event::Test { }
class Event::DoneTesting is Event::Report { }
class Event::BailOut is Event::Report { }
