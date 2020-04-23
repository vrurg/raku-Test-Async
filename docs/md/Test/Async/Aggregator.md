NAME
====

`Test::Async::Aggregator` - event collecting and processing

SYNOPSIS
========

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

DESCRIPTION
===========

This role implements event collection and dispatching.

Event Loop
----------

The role implements two-stage event event processing:

  * The first stage is fetching of an event from event queue [`Channel`](https://docs.raku.org/type/Channel) and passing it to a `filter-event` method. Then the resulting event is pushed into a local buffer.

  * The second stage is a loop pulling all events from the buffer and feeding them to the `event` method.

A reason for this approach to be taken is to allow the `filter-event` method to add custom events directly to the buffer for immediate processing. It can do it directly, using `post-event` method; or indirectly, by returning a list of events.

Special care is taken of `Event::Terminate`. When the dispatcher encounters an event of this type it pulls in all remaining events from the channel, filters them, and pushes into the buffer. Then, after emptying the buffer, it fulfills the vow supplied with the event object and terminates event loop `react` block.

METHODS
=======

`start-event-loop`
------------------

Starts a thread where it listens for new events on the queue and dispatches them.

`create-event(Event:U \evType, *%profile)`
------------------------------------------

Create a new event instance from event class `evType`. `%profile` is used as event constructor profile. Method sets event's `origin` attribute to `self`.

`multi send(Event:D $ev)`
-------------------------

`multi send(Event:U $ev, *%profile)`
------------------------------------

Sends an event in the event queue for dispatching. If supplied with an event type object then instantiates it using `%profile` and then sends the new instance.

`multi post-event(Event:D $ev)`
-------------------------------

`multi post-event(Event:U \evType, *%profile)`
----------------------------------------------

`multi post-event(*@events)`
----------------------------

Pushes an event into the local buffer. If event type is supplied then it gets instantiated first and then pushed.

**Note!** The method can only be used within the event loop thread. If called outside it throws `X::BadPostEvent`.

SEE ALSO
========

[`Test::Async::Manual`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Manual.md), [`Test::Async::Event`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Event.md), [`Test::Async::Utils`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Utils.md), [`Test::Asynx::X`](https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Asynx/X.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

