use v6;
use Test::Async <Base>;

# Be explicit about the mode of operation, no parallel, no randomization are allowed.
plan 15, :!parallel, :!random;

my @default-args = '-I' ~ $?FILE.IO.parent(2).add('lib'), '-MTest::Async';
my $job-count = test-suite.test-jobs;

# Catch the simplest errors here.
subtest "Simple" => {
    pass "simple";
}

is-run q:to/TEST-CODE/, "basic subtest",
       plan 1;
       subtest "simple" => {
           pass "subtest 1";
       };
       TEST-CODE
       :compiler-args(@default-args),
       :exitcode(0),
       :err(''),
       :out(/^"1..1\n  ok 1 - subtest 1\n  1..1\nok 1 - simple\n"/);

is-run q:to/TEST-CODE/, "sequential",
       plan 2;
       subtest "simple 1" => {
           pass "subtest 1-1";
       };
       subtest "simple 2" => {
           plan 1;
           pass "subtest 2-1";
       };
       TEST-CODE
       :compiler-args(@default-args),
       :exitcode(0),
       :err(''),
       :out(
            /
                ^"1..2\n  ok 1 - subtest 1-1\n  1..1\nok 1 - simple 1\n"
                ^^"  1..1\n  ok 1 - subtest 2-1\nok 2 - simple 2\n"
            /
       );

is-run q:to/TEST-CODE/, "hidden subtest",
       use Test::SubBundle;
       use Test::Async <Base>;
       plan 1;
       test-hidden-subtest;
       TEST-CODE
       :compiler-args(@default-args[0], '-I' ~ $?FILE.IO.parent(1).add('lib/060-subtest/lib')),
       :exitcode(1),
       :err(''),
       :out(
            /
                ^"1..1\n  1..1\n  not ok 1 - must report test-hidden-subtest CallFrame\n"
                "  # You failed 1 test of 1\nnot ok 1 - hidden\n"
                "# Failed test 'hidden'\n# at " .*? " line 4"
            /
       );

subtest "subtest topic" => {
    .plan: 1;
    .cmp-ok: $_, '===', test-suite, "topic is set to the test suite object";
}

# as of when this is written, isa-ok isn't implemented yet...
ok (my $completion = subtest "dummy" => { pass }) ~~ Promise, "subtest returns a completion Promise";
is $completion.status, Kept, "subtest completion promise is kept when subtest is done";

subtest "TODO in plan" => {
    plan 1, :todo("on subtest voids errors");
    flunk "this would be a failure without TODO";
}

todo "subtest fails";
subtest "TODO before subtest" => {
    flunk "this test fails but the subtest is TODO";
}

sub test-async($count, :%subtest-plan) {
    my $suite = test-suite;

    my atomicint $started = 0;
    my $starter = Promise.new;
    my @subtests-ready;
    my @subtests-complete;
    for ^$count -> $id {
        @subtests-ready.push: my $subtest-ready = Promise.new;
        @subtests-complete.push:
            subtest "job $id" => {
                plan 4;
                # Sync with the parent suite.
                is $started, 0, "no concurrent subtests really started yet";
                $subtest-ready.keep($id);
                await $starter;
                ++⚛$started;
                pass "subtest $id started";

                # Test for our internal status
                my $suite = test-suite; # Take his subtest object.
                nok $suite.parallel, "a child suite is non-parallel by default";
                ok $suite.is-async, "but its async status is inherited";
            }, |%subtest-plan
    }
    my Bool $all-ready;

    # Await for concurrent subtests to start and prepare.
    await Promise.anyof(
        Promise.in(30).then({ cas $all-ready, Bool, False }),
        Promise.allof(@subtests-ready).then({ cas $all-ready, Bool, True }),
    ) unless $suite.skip-message;

    ok $all-ready, "all subtests are ready and waiting";

    $starter.keep(True);

    # Await for subtests to complete.
    my Bool $all-completed;
    await Promise.anyof(
        Promise.in(30).then({ cas $all-completed, Bool, False }),
        Promise.allof(@subtests-complete).then({ cas $all-completed, Bool, True }),
    ) unless $suite.skip-message;

    ok $all-completed, "all subtests completed";
    is $started, $count, "counter updated by all subtests";
}

subtest "Parallel subtests" => {
    # Test will fail if we try to start more than maximum allowed jobs because some subtests won't run until a slot
    # releases.

    my %plan-profile = skip-all => "must be 2 or more concurrent jobs allowed, $job-count now" if $job-count < 2;

    plan $job-count + 3,
         :parallel,
         |%plan-profile;

    test-async $job-count;
}

subtest "Force async" => {
    plan $job-count + 3, :!parallel, :!random;

    test-async $job-count, :subtest-plan{ :async, :instant };
}

subtest "Threading in a subtest" => {
    my $suite = test-suite;
    plan $job-count;

    for ^$job-count -> $id {
        $suite.start: {
            sleep .1.rand;
            pass "test $id";
        }
    }
}

subtest "Subtest returns" => {
    plan 8;
    my $sres = await subtest "passing subtest" => {
        plan 1;
        pass "just pass";
    };
    ok $sres, "successfull subtest returns a Promise kept with True";
    $sres = await subtest "no plan but passing" => {
        pass "pass 1";
        pass "pass 2";
    }
    ok $sres, "successfull subtest with no plan still returns a Promise kept with True";
    test-flunks;
    $sres = await subtest "flunking subtest" => {
        plan 1;
        flunk "just flunk";
    }
    nok $sres, "flunking subtest returns a Promise kept with False";
    test-flunks;
    $sres = await subtest "bad plan subtest" => {
        plan 2;
        pass "single pass";
    }
    nok $sres, "bad plan subtest returns a Promise kept with False";
}

# We can't rely on the order test to determine if it was random. However low is the probability to get them ordered
# straight, it is no 0. Let's not write intentionally flapping test!
# What we can do though is conisder a side effect of the randomization: all subtests will be ran last when the test body
# execution is over.
is-run q:to/TEST-CODE/, "sequential",
       my $count = 3;
       plan $count + 1, :random;

       for ^$count -> $id {
           subtest "job $id" => {
               plan 1;
               pass "dummy $id";
           }
       }
       pass "this will preceede subtests";
       TEST-CODE
       :compiler-args(@default-args),
       :exitcode(0),
       :err(''),
       :out(
            /
                ^"1..4\nok 1 - this will preceede subtests\n"
                ^^"  1..1\n  ok 1 - dummy " \d "\nok 2 - job " \d \n
                ^^"  1..1\n  ok 1 - dummy " \d "\nok 3 - job " \d \n
                ^^"  1..1\n  ok 1 - dummy " \d "\nok 4 - job " \d \n
            /
       );

done-testing;
