use v6;
use Test::Async::Decl;

unit test-bundle Foo;

my role RF { }

method get_role { RF }
