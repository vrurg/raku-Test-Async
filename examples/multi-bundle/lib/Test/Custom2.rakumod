use v6;
use Test::Async::Decl;

unit test-bundle Test::Custom2;

use Test::Async::Event;
use Test::Async::Utils;

method custom2(Str:D $message) is test-tool {
    self.send-test: Event::Ok, "custom2: " ~ $message, TRPassed
}
