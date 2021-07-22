use v6;
use Test::Async;

BEGIN {
    $*SCHEDULER = ThreadPoolScheduler.new: max-threads => 256;
}

plan 16, :parallel, :test-jobs(4);

class MyApp { 
    has $.attr = rand;
    has Promise:D $.stop .= new;
    has Promise $.completed is rw;
    method run {
        self.start-worker;
        self.main;
    }
    method start-worker {
        $.completed = start self.worker;
    }
    method worker {
        while !$!stop {
            self.get-sensor;
        }
    }
    method get-sensor {
        sleep 0.105.rand;
    }
    method main {
        await $.stop;
    }
}

class MyTestApp is MyApp {
    has Test::Async::Hub:D $.test-suite is required; 
    has Int:D $!attempts is built is required;
    method start-worker {
        $.completed = $.test-suite.start: { self.worker }
    }
    method get-sensor {
        callsame;
        my $delta = now - ENTER now;
        $.test-suite.cmp-ok: $delta, "<", 0.1, "sensor is fast enough";
        $.stop.keep if --$!attempts < 1;
    }
}

for ^16 -> $n {
    subtest "App tester $n", -> $test-suite {
        my $attempts = 3;
        plan $attempts;
        my $app = MyTestApp.new: :$test-suite, :$attempts;
        $app.run;
    }
}

done-testing;
