use v6;
unit role Test::Async::TestTool;
has $.tool-name;
has Bool:D $.readify = True;
has Bool:D $.skippable = True;

method set-tool-name(Str:D $!tool-name)    { }
method set-readify(Bool:D $!readify) { }
method set-skippable(Bool:D $!skippable)   { }
