use v6;
use lib $?FILE.IO.parent(1).add('lib');
use Test::Bootstrap;
use Test::Async::JobMgr;
use Test::Async::Job;

plan 10;

{ # See if Test::Async::Job handles it's promise if job code throws.
    my $value = 1.rand;
    my $job = Test::Async::Job.new(
        code => -> { $value }
    );

    $job.invoke;
    ok ($job.promise.status ~~ Kept), "job promise is kept when its code is done ok";
    ok $job.promise.result == $value, "job promise result is its code return value";

}

{ # See if Test::Async::Job handles it's promise if job code throws.
    my class TAsync::X::OkiDoki is Exception { }
    my $job = Test::Async::Job.new(
        code => -> {
            TAsync::X::OkiDoki.new.throw;
        }
    );

    try $job.invoke;
    ok ($job.promise.status ~~ Broken), "job promise is broken when its code throws";
    ok $job.promise.cause ~~ TAsync::X::OkiDoki, "job promise cause is the exception thrown";
}

my class TestJobs does Test::Async::JobMgr {
    has $.test-jobs = 4;

    method fatality(Int:D $exit-code = 255) {
        die "Unexpected fatality, exit code " ~ $exit-code
    }

    method x-sorry(Exception:D $ex, :$comment) {
        $ex.rethrow
    }
}

my $tj = TestJobs.new;

my $count = 10;
my $starter = Promise.new;
my atomicint $started = 0;
my $max-reached = False;
my @jobp = Promise.new xx $count;
for ^$count -> $id {
    $tj.start: {
        $max-reached ||= ++⚛$started == $count;
        @jobp[$id].keep(True);
        await $starter;
    }
}
await Promise.anyof(
    Promise.in(10),
    Promise.allof(@jobp),
);
$starter.keep(True);
ok $max-reached, "all concurrent jobs started";

my class NotDone {};
my $awaited-ok = NotDone;
await Promise.anyof(
    Promise.in(10).then({ cas $awaited-ok, NotDone, False }),
    (start { $tj.await-all-jobs }).then({ cas $awaited-ok, NotDone, True }),
);

ok $awaited-ok, "all started threads completed";
ok $tj.job-count == 0, "no remaining jobs left";

$tj = TestJobs.new;

$started ⚛= 0;
my $over-use = False;
@jobp = Promise.new xx $count;
for ^$count -> $id {
    $tj.start-job: {
        $over-use ||= $started > $tj.test-jobs;
        @jobp[$id].keep(True);
        sleep 0.1; # Don't finish too soon, make the queue work.
        --⚛$started;
    };
    ++⚛$started;
}

await Promise.anyof(
    Promise.in(10),
    Promise.allof(@jobp)
);

ok !$over-use, "never had more than max allowed number of jobs";

$awaited-ok = NotDone;
await Promise.anyof(
    Promise.in(10).then({ cas $awaited-ok, NotDone, False }),
    (start { $tj.await-all-jobs }).then({ cas $awaited-ok, NotDone, .status ~~ Kept }),
);

ok $awaited-ok, "all started jobs completed";
ok $tj.job-count == 0, "no remaining jobs left";

done-testing;
