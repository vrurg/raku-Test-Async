use v6;
use Test::Async::Decl;
use Test::Async::Utils;

unit test-bundle Test::SubBundle;

method test-hidden-flunking(Str:D $tool-name) is test-tool {
    self.flunk: "must report $tool-name CallFrame";
}

method test-hidden-subtest(Str:D $tool-name = "test-hidden-subtest") is test-tool {
    self.subtest: "hidden", :hidden, -> \suite {
        suite.plan: 1;
        suite.test-hidden-flunking($tool-name);
    }
}

method test-hidden-in-hidden is test-tool {
    self.subtest: "hidden in hidden", :hidden, :instant, -> \suite {
        suite.test-hidden-subtest("test-hidden-in-hidden");
    }
}

method test-tool-with-anchor(Str:D $tool-name = "test-tool-with-anchor") is test-tool(:!wrap) {
    self.anchor: {
        self.test-hidden-subtest: $tool-name;
    }
}

method test-tool-anchoring(Str:D $tool-name = "test-tool-anchoring") is test-tool(:anchoring) {
    # Introduce an additional frame and make sure it won't be optimized away by using .rand
    unless 1.rand > 2 {
        self.test-hidden-subtest: $tool-name
    }
}
