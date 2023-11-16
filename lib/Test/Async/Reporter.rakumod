use v6;


unit role Test::Async::Reporter;
use Test::Async::Event;

method report-event(Event:D) {...}
method indent-message(+@message, :$prefix, :$nesting, *% --> Array()) {...}
method message-to-console(+@message) {...}
