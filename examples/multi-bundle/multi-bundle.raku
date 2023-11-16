#!/usr/bin/env raku
use lib $?FILE.IO.parent(1).add("lib");
use Test::Custom1;
use Test::Custom2;
use Test::Async;

custom1 "test1";
custom2 "test2";

say "MRO: ", test-suite.^mro.map( *.^name ).join(", ");
