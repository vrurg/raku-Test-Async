use v6;

=begin pod
=head1 NAME

C<Test::Async::Event> – collection of standard events

=head1 SYNOPSIS

    use Test::Async::Event;

    test-bundle MyBundle {
        method foo(Str:D $message) is test-tool {
            self.send-test: Event::Ok, :$message
        }
    }

=DESCRIPTION

General information about C<Test::Async> event management can be found in
L<C<Test::Async::Manual>|Manual.md>.

Events are objects of classes derived from C<Event> class. This module provides support for C<Test::Async> core. In
general, all event classes can be conventionally split into the following groups:

=item I<informative> – events signalling about some state changes. Like, for example, suite termination.
=item I<reporting> - events bearing a message to be reported to user.
=item I<commands> – those which tell the core to perform an action.
=item I<tests> – outcomes of individual test tools.

=head2 Class C<Event>

The base event class.

=head3 Attributes

=item C<$.origin> – event originating object. Defaults to the current test suite object.
=item C<Int:D $.id> – event id, a sequential number.
=item C<Instant:D $.time> – the moment when event object was created.

=head3 Methods

=item C<Profile> – returns a L<C<Map>|https://docs.raku.org/type/Map> suitable for passing to an event constructor. The
method collects all changed public attributes of an object.
=item C<gist>, C<Str> – stringify event object for reporting.

=head1 EVENT SUBCLASSES

=item L<C<Event::BailOut>|Event/BailOut.md>
=item L<C<Event::Command>|Event/Command.md>
=item L<C<Event::Diag>|Event/Diag.md>
=item L<C<Event::DoneTesting>|Event/DoneTesting.md>
=item L<C<Event::JobsAwaited>|Event/JobsAwaited.md>
=item L<C<Event::NotOk>|Event/NotOk.md>
=item L<C<Event::Ok>|Event/Ok.md>
=item L<C<Event::Plan>|Event/Plan.md>
=item L<C<Event::Report>|Event/Report.md>
=item L<C<Event::Skip>|Event/Skip.md>
=item L<C<Event::StageTransition>|Event/StageTransition.md>
=item L<C<Event::Telemetry>|Event/Telemetry.md>
=item L<C<Event::Terminate>|Event/Terminate.md>
=item L<C<Event::Test>|Event/Test.md>

=head2 Command event classes C<Event::Cmd::*>

A bundle of events used internally for commands. See
L<C<Test::Async::Hub>|Hub.md>
and possibly other modules. The set of command events is not standartized and subject for changes.

=head1 SEE ALSO

L<C<Test::Async::Manual>|Manual.md>,
L<C<Test::Async::Aggregator>|Aggregator.md>,
L<C<Test::Async::Hub>|Hub.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

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
