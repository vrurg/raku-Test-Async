use v6;

unit role Test::Async::Aggregator;

use Test::Async::Utils;
use Test::Async::Event;

has Channel:D $!ev-queue .= new;
has @!posted-events;

multi method create-event(Event:U \evType, %c) {
    evType.new(:origin(self), |%c)
}
multi method create-event(Event:U \evType, *%c) {
    evType.new(:origin(self), |%c)
}

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
    self.port-event: evType.new(|%c)
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
        exit 1;
    }
    self.post-event: self.?filter-event($ev) // $ev;
    my $terminate = False;
    while @!posted-events {
        my $event = @!posted-events.shift;
        if $event ~~ Event::Terminate {
            # Pull in any possibly remaining events.
            while $!ev-queue.poll {
                self.post-event: $_
            }
            $terminate = True;
        }
        else {
            self.event: $event;
        }
        if $terminate {
            $event.completed.keep(True);
            done;
        }
    }
}
