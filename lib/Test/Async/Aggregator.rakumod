use v6;


unit role Test::Async::Aggregator;

use Test::Async::Utils;
use Test::Async::Event;

has Channel:D $!ev-queue .= new;
has @!posted-events;

method fatality(Int:D $?) {...}

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
    # self.trace-out: "--> EV: [" ~ self.id.fmt('%5d') ~ "] " ~ $ev;
    $!ev-queue.send($ev);
}
multi method send(Event:U \evType, *%c) {
    self.send: self.create-event(evType, %c)
}

method try-send(|c) {
    CATCH {
        when X::Channel::SendOnClosed {
            return
        }
        default {
            .rethrow
        }
    }
    self.send: |c
}

proto method post-event(Event, *%) {*}
multi method post-event(Event:D $ev) {
    self.throw: Test::Async::X::BadPostEvent, :owner($*TEST-ASYNC-EV-OWNER)
        unless $*TEST-ASYNC-EV-OWNER === self;
    @!posted-events.push: $ev;
}
multi method post-event(Event:U \evType, *%c) {
    self.post-event: evType.new(|%c)
}
multi method post-event(*@events where *.elems > 1) {
    self.post-event: $_ for @events;
}

my class DoneEventLoop is X::Control { }
method start-event-loop {
    # self.trace-out: "!!!!! start event loop";
    start {
        # react whenever $!ev-queue -> $ev {
        EVLOOP:
        loop {
            my $ev = $!ev-queue.receive;
            # self.trace-out: "<-- EV: [" ~ self.id.fmt('%5d') ~ "] " ~ $ev;
            CONTROL {
                when DoneEventLoop {
                    last EVLOOP;
                }
                default {
                    .rethrow
                }
            }
            CATCH {
                CATCH { note "EXCEPTION HANDLING IN EVENT LOOP DIED WITH: ", .message, "\n", .backtrace.Str.indent(2) }
                # self.trace-out: "===EVENT HANDLING=== ", $_, ~$_.backtrace;
                self.x-sorry: $_, :comment("In event handling.");
                my $drop-ev = $ev;
                repeat {
                    $drop-ev.terminated.keep($_ but False) if $drop-ev ~~ Event::Terminate;
                    $drop-ev = $!ev-queue.poll;
                } while $drop-ev;
                $!ev-queue.fail($_);
                self.fatality(exception => $_, :event-queue);
            }
            self!dispatch-event($ev);
            # self.trace-out: "<!! DISPATCHED EV: [" ~ self.id.fmt('%5d') ~ "] " ~ $ev.^name ~ "#" ~ $ev.id;
        }
    }
}

method event-queue-is-active(--> Bool:D) {
    $!ev-queue.closed.status ~~ Planned
}

method !dispatch-event(Event:D $ev) {
    my $*TEST-ASYNC-EV-OWNER = self;
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
        # self.trace-out: "!!! GOT TERMINATION EVENT";
        .terminated.keep(True);
        $!ev-queue.close;
        DoneEventLoop.new.throw
        # done;
    }
}
