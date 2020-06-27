use v6;

=begin pod
=head1 NAME

C<Test::Async::Aggregator> - event collecting and processing

=head1 SYNOPSIS

    class MyHub does Test::Async::Aggregator {
        my class Event::My {
            has $.data;
        }

        submethod TWEAK {
            self.start-event-loop;
        }

        method foo {
            ...;
            self.send: Event::My, :$data;
        }
    }

=head1 DESCRIPTION

This role implements event collection and dispatching.

=head2 Event Loop

The role implements two-stage event event processing:

=item The first stage is fetching of an event from event queue L<C<Channel>|https://docs.raku.org/type/Channel> and
passing it to a `filter-event` method. Then the resulting event is pushed into a local buffer.
=item The second stage is a loop pulling all events from the buffer and feeding them to the `event` method.

A reason for this approach to be taken is to allow the `filter-event` method to add custom events directly to the buffer
for immediate processing. It can do it directly, using `post-event` method; or indirectly, by returning a list of
events.

Special care is taken of C<Event::Terminate>. When the dispatcher encounters an event of this type it pulls in all
remaining events from the channel, filters them, and pushes into the buffer. Then, after emptying the buffer, it
fulfills the vow supplied with the event object and terminates event loop C<react> block.

=head1 METHODS

=head2 C<start-event-loop>

Starts a thread where it listens for new events on the queue and dispatches them.

=head2 C<create-event(Event:U \evType, %profile)>
=head2 C<create-event(Event:U \evType, *%profile)>

Create a new event instance from event class C<evType>. C<%profile> is used as event constructor profile. Method sets
event's C<origin> attribute to C<self>.

=head2 C<multi send(Event:D $ev)>
=head2 C<multi send(Event:U $ev, *%profile)>

Sends an event in the event queue for dispatching. If supplied with an event type object then instantiates it using
C<%profile> and then sends the new instance.

=head2 C<multi post-event(Event:D $ev)>
=head2 C<multi post-event(Event:U \evType, *%profile)>
=head2 C<multi post-event(*@events)>

Pushes an event into the local buffer. If event type is supplied then it gets instantiated first and then pushed.

B<Note!> The method can only be used within the event loop thread. If called outside it throws C<X::BadPostEvent>.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.14/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Event>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.14/docs/md/Test/Async/Event.md>,
L<C<Test::Async::Utils>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.14/docs/md/Test/Async/Utils.md>,
L<C<Test::Asynx::X>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.14/docs/md/Test/Asynx/X.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit role Test::Async::Aggregator;

use Test::Async::Utils;
use Test::Async::Event;

has Channel:D $!ev-queue .= new;
has @!posted-events;

proto method event(Event, |) {*}
# Drop unprocessed events.
multi method event(Event:D $ev) { }

proto method create-event(Event:U, |) {*}
multi method create-event(Event:U \evType, %c) {
    evType.new(:origin(self), |%c)
}
multi method create-event(Event:U \evType, *%c) {
    evType.new(:origin(self), |%c)
}

proto method send(Event, |) {*}
multi method send(Event:D $ev) {
    $!ev-queue.send($ev);
}
multi method send(Event:U \evType, *%c) {
    self.send: self.create-event(evType, %c)
}

proto method post-event(Event, *%) {*}
multi method post-event(Event:D $ev) {
    self.throw: X::BadPostEvent, :owner($*TEST-ASYNC-EV-OWNER)
        unless $*TEST-ASYNC-EV-OWNER === self;
    @!posted-events.push: $ev;
}
multi method post-event(Event:U \evType, *%c) {
    self.post-event: evType.new(|%c)
}
multi method post-event(*@events where *.elems > 1) {
    self.post-event: $_ for @events;
}

method start-event-loop {
    start react whenever $!ev-queue -> $ev {
        self!dispatch-event($ev);
    }
}

method !dispatch-event(Event:D $ev) {
    my $*TEST-ASYNC-EV-OWNER = self;
    CATCH {
        note "===EVENT HANDLING=== ", $_, ~$_.backtrace;
        exit 255;
    }
    self.post-event: self.?filter-event($ev) // $ev;
    my $term-event;
    while @!posted-events {
        my $event = @!posted-events.shift;
        if $event ~~ Event::Terminate {
            # Pull in any possibly remaining events.
            while $!ev-queue.poll -> $rev {
                self.post-event: self.?filter-event($rev) // $rev;
            }
            $term-event = $event;
        }
        else {
            self.event: $event;
        }
    }
    with $term-event {
        .terminated.keep(True);
        done;
    }
}
