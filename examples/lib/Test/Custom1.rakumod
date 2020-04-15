use v6;
use Test::Async::Decl;

unit test-bundle Test::Custom1;

use Test::Async::Event;
use Test::Async::Utils;

method custom1(Str:D $message) is test-tool {
    self.send-test: Event::Ok, "custom1: " ~ $message, TRPassed
}
