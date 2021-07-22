use v6;
use Test::Async;

plan 10;

class MyApp { 
    has $.attr = rand;
    has Promise:D $.stop .= new;
    has Promise $.completed is rw;
    method run {
        $.completed = start self.worker;
    }
    method worker {
        while !$!stop {
            self.get-sensor;
        }
    }
    method get-sensor {
        sleep 0.15.rand;
    }
}

class MyTestApp is MyApp {
    has Test::Async::Hub:D $.test-suite is required; 
    has Int:D $!tried = 0;
    method run {
        $.completed = $.test-suite.start: { self.worker }
    }
    method get-sensor {
        callsame;
        my $delta = now - ENTER now;
        $.test-suite.cmp-ok: $delta, "<", 0.1, "sensor is fast enough";
        $.stop.keep if ++$!tried >= 10;
    }
}

my $app = MyTestApp.new: :test-suite(test-suite);

$app.run;
