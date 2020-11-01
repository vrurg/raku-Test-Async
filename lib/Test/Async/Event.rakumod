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
L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Manual.md>.

Events are objects of classes derived from C<Event> class. This module defines events used by the core. In general,
all event classes can be conventionally split into the following groups:

=item I<informative> – events signalling about some state changes. Like, for example, suite termination.
=item I<reporting> - events bearing a message to be reported to user.
=item I<commands> – those which tell the core to perform an action.
=item I<tests> – outcomes of individual test tools.

=head1 EXPORTED CLASSES

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

=head2 Class C<Event::Report>

Is C<Event>.

Base class for events carrying a text message of any kind.

=head3 Attributes

=item C<Str:D $.message> – the event message

=head2 Class C<Event::Command>

Is C<Event>.

Base class of commanding events.
L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Hub.md>
handles them specially.

=head3 Attributes

=item C<Capture:D $.args> – command arguments

=head2 Class C<Event::Test>

Is C<Event::Report>

Base class for events reporting test outcomes.

=head3 Attributes

=item C<Str $.todo> – message to use if test is marked as I<TODO>.
=item C<Str $.flunks> – message to use if test is marked as anticipated failure (see C<test-flunks> in
L<C<Test::Async::Base>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Base.md>.
=item C<CallFrame:D $.caller>, required – position in user code where the test was called.
=item C<@.child-messages> – messages from child suites. Each entry should be a single line ending with newline.
=item C<@.comments> – comments for the test. Normally expected to be reported with C<diag>. Not special formatting
requirements except for a recommendation for the last line not to end with a newline.

=head2 Class <Event::StageTransition>

Emitted each time suite stage is changed.

=head3 Attributes

=item C<$.from> – the stage before transition
=item C<$.to> – the stage after transition

=head2 Class <Event::JobsAwaited>

Emitted when all pending jobs are completed.

=head2 Class C<Event::Terminate>

Is C<Event>.

This is the only kind of event which
L<C<Term::Async::Aggregator>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Term/Async/Aggregator.md>
role cares about. It tells the event loop to pull any remaining events from the queue and dispatch them immediately.
Then it fulfills event's promise.

=head3 Attributes

=item C<Promise::Vow $.completed>, required – a promise vow to be kept when event loop finishes processing all remaining
events.

=head2 Class C<Event::Telemetry>

Is C<Event>

Under development yet.

=head2 Class C<Event::Plan>

Is C<Event::Report>

Plan reporting event. Emitted when a suite gets to know the number of tests to be done.

=head3 Attributes

=item C<Bool $.skip> – suite is planned for skiping.
=item C<UInt:D $.planned>, required - number of tests planned.

=head2 Class C<Event::Diag>

Is C<Event::Report>.

Carries a diagnostics message. See C<diag> in L<C<Test::Async::Base>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Base.md>.

=head2 Class C<Event::Ok>

Is C<Event::Test>.

Test passed.

=head2 Class C<Event::NotOk>

Is C<Event::Test>.

Test flunked.

=head2 Class C<Event::Skip>

Is C<Event::Test>.

Test skipped.

=head2 Class C<Event::DoneTesting>

Is C<Event::Report>.

Emitted when testing is completely done.

=head2 Class C<Event::BailOut>

Is C<Event::Report>

Emitted when test suite is about to bail out.

=head2 Command event classes C<Event::Cmd::*>

A bundle of events used internally for commands. See L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Hub.md> and possibly other modules. The set of
command events is not standartized and subject for changes.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Aggregator>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Aggregator.md>,
L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.15/docs/md/Test/Async/Hub.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

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
    has CallFrame:D $.caller is required;
    has @.child-messages;
    has @.comments;
}

class Event::Terminate is Event {
    has Promise:D $.terminated .= new;
}

class Event::StageTransition is Event {
    has $.from is required;
    has $.to is required;
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
