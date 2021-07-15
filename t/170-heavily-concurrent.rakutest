use Test::Async <When Base>;

constant MAX-THREADS = 2000;
constant CONC-COUNT = 1000;
BEGIN {
    %*ENV<RAKUDO_MAX_THREADS> = MAX-THREADS;
#    %*ENV<TEST_JOBS> = CONC-COUNT;
}

$*SCHEDULER = ThreadPoolScheduler.new;

my $count = 1000;
# 5 minutes
my $timeout = 300;

plan $count + 2,
    :parallel, :!random,
    :test-jobs(CONC-COUNT),
    :job-timeout(120),
    :when( <stress> );

is $*SCHEDULER.max_threads, MAX-THREADS, "max threads set";

my $starter = Promise.new;
for ^$count -> $id {
    subtest "test $id" => {
        await $starter;
        plan 1;
        pass "started $id";
    }
}

pass "all started";
$starter.keep(1);

done-testing;
