use v6;
unit role Test::Async::JobMgr;
use Test::Async::Job;
use Test::Async::X;

method test-jobs {...}

has @.postponed;
has Lock:D $!postponed-lock .= new;

has %!job-idx;
has Lock:D $!idx-lock .= new;

has Channel:D $!jobs-done .= new;
# start-job promises awaiting for their turn.
has Channel:D $!requests .= new;

has atomicint $!active-count = 0;
has %!active-jobs;
has Lock::Async:D $!active-lock .= new;

submethod TWEAK(|) {
    # Remove any finished job from active ones.
    $!jobs-done.Supply.tap: { 
        self.release-job($_);
    };
}

method job-count {
    $!idx-lock.protect: { %!job-idx.elems }
}

method new-job(Callable:D $code is raw, :$async = False) {
    my $job = Test::Async::Job.new:
                :$async,
                code => {
                    my $*TEST-SUITE = self;
                    CATCH {
                        note "===SORRY! JOB #", $job.id, " DIED=== ", $_;
                        exit 255;
                    }
                    $code()
                };
    $!idx-lock.lock;
    LEAVE $!idx-lock.unlock;
    %!job-idx{$job.id} = $job
}

method all-job-promises {
    $!idx-lock.protect: {
        %!job-idx.values».promise.grep( *.defined )
    }
}

method active-job-promises {
    $!active-lock.protect: {
        %!active-jobs.values».promise
    }
}

proto method release-job(|) {*}
multi method release-job(Int:D $id) {
    self.release-job: self.job-by-id($id)
}

multi method release-job(Test::Async::Job:D $job) {
    $!idx-lock.lock;
    LEAVE $!idx-lock.unlock;
    %!job-idx{$job.id}:delete;
}

proto method postpone(|) {*}
multi method postpone(Callable:D \code, :$async = False) {
    self.postpone: self.new-job(code, :$async);
}
multi method postpone(Test::Async::Job:D $job) {
    $!postponed-lock.protect: {
        @!postponed.push: $job;
    }
}

method job-by-id(Int:D $id) {
    %!job-idx{$id} // self.throw(X::NoJobId, :$id);
}

# Start a parallel job, respect $.test-jobs
proto method start-job(|) {*}
multi method start-job(Int:D $id, |c) {
    self.start-job: self.job-by-id($id)
}

multi method start-job(Callable:D \code) {
    self.start-job: self.new-job(code)
}

multi method start-job(Test::Async::Job:D $job) {
    my $request-promise = Promise.new;
    $request-promise.then: {
        $!active-lock.protect: { %!active-jobs{$job.id} = $job };
    }
    $!active-lock.protect: {
        if %!active-jobs.elems >= $.test-jobs {
            $!requests.send: $request-promise;
        }
        else {
            %!active-jobs{$job.id} = $job;
            $request-promise.keep(True);
        }
    }
    await $request-promise;
    (self.start: $job).then: {
        self!stop-job($job);
    }
}

method !stop-job(Test::Async::Job:D $job) {
    my $next-request;
    $!active-lock.protect: {
        my $id = $job.id;
        self.throw(X::JobInactive, :$id) unless %!active-jobs{$id}:exists;
        %!active-jobs{$id}:delete;
        $next-request = $!requests.poll;
    }
    # Fullfill promise of the next awaiting start-job
    .keep(True) with $next-request;
}

# Invoke job instantly
proto method invoke-job(|) {*}
multi method invoke-job(Int:D $id) {
    self.invoke-job: self.job-by-id($id);
}

multi method invoke-job(Test::Async::Job:D $job) {
    ( $job.async ?? $job.start !! $job.invoke ).then: {
        $!jobs-done.send: $job;
        .result
    }
}

# Async start job instantly. Must not be evaded as it takes responsibility of removing completed jobs from the index.
proto method start(|) {*}
multi method start(Int:D $id) {
    self.start: self.job-by-id($id)
}

multi method start(Callable:D \code) {
    self.start: self.new-job(code)
}

multi method start(Test::Async::Job:D $job) {
    $job.start.then: {
        $!jobs-done.send: $job;
        .result
    }
}

method await-all-jobs {
    $!postponed-lock.protect: {
        self.throw: X::AwaitWithPostponed, :count(+@!postponed) if @!postponed;
    }
    repeat {
        my @p = self.all-job-promises;
        await Promise.allof(@p) if @p;
    } while %!job-idx;
}
