use v6;
use Test::Async::Decl;

test-bundle FooBundle {
    method is-foo(Str:D $got, Str:D $message) is test-tool {
        self.is: $got.fc, 'foo'.fc, $message;
    }
}

use Test::Async <Base>;

is-foo "Foo", "as a routine";
test-suite.is-foo: "Foo", "as a method call";
