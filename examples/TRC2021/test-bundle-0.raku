use v6;
use Test::Async::Decl;

test-bundle FooBundle {
    method is-foo(Str:D $got, Str:D $message) is test-tool {
        self.proclaim: ($got.lc eq 'foo'), $message;
    }
}

use Test::Async <Base>;

is-foo "Foo", "it is";
is-foo "Bar", "it is not";
