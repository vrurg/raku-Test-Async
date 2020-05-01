use v6;
use Test::Async::Decl;
use Test::Async::Utils;

unit test-bundle Test::SubBundle;

method test-hidden-subtest is test-tool {
    test-suite.subtest: "hidden", :hidden, :instant, {
        .plan: 1;
        .flunk: "must report test-hidden-subtest CallFrame";
    }
}
