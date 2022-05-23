use v6.d;
use Test::Async::Decl;

package EXPORT::DEFAULT {
    our sub my-export($v) { "The Answer " ~ $v }
}

test-bundle Exporting::Bundle {
}