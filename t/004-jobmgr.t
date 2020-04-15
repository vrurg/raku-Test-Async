use v6;
use lib $?FILE.IO.parent(1).add('lib');
use Test::Bootstrap;
use Test::Async::JobMgr;
use Test::Async::Job;

plan 4;

my class TestJobs does Test::Async::JobMgr {
    has $.test-jobs = 4;
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

my $awaited-ok;
await Promise.anyof(
    Promise.in(10).then({ cas $awaited-ok, Any, False }),
    (start { $tj.await-all-jobs }).then({ cas $awaited-ok, Any, True }),
); 

$awaited-ok &&= $tj.job-count == 0;

ok $awaited-ok, "all started threads completed";

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

$awaited-ok = Nil;
await Promise.anyof(
    Promise.in(10).then({ cas $awaited-ok, Any, False }),
    (start { $tj.await-all-jobs }).then({ cas $awaited-ok, Any, True }),
); 

$awaited-ok &&= $tj.job-count == 0;

ok $awaited-ok, "all started jobs completed";

done-testing;
