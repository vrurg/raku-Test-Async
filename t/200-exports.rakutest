use v6.d;
use lib $?FILE.IO.parent(1).add('lib/200-exports/lib');
use Test::Async <Base Exporting::Bundle>;

plan 2;

ok LEXICAL::<&my-export>:exists, "bundle exports via EXPORT::DEFAULT";
my $rand = 42.rand;
is my-export($rand), "The Answer " ~ $rand, "the exported sub is what we expect";

done-testing;
