use v6;

=begin pod
=head1 NAME

C<Test::Async::JobMgr> – job management role

=head1 SYNOPSIS

    class MyApp does Test::Async::JobMgr {
        method foo {
            self.start-job: self.new-job( { self.worker-method }, :async );
        }
        method shutdown {
            self.await-all-jobs;
        }
    }

=DESCRIPTION

This role implements job management functionality, as described in section Job Management of
L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.4/docs/md/Test/Async/Manual.md>.

=head2 Implementation Details

All jobs are kept in unordered "pool" and identified either by the object representing them, or by unique numeric ID
assigned to each job.

Jobs are grouped into three categories:

=item I<active> - managed jobs, whose maximum number of concurrent instances is limited. Start with C<start-job>.
=item I<postponed> – jobs which are to be invoked later, when the consuming class decides it.
=item I<waiting> - those scheduled for execution but awaiting for a free slot.

A completed job is removed from the pool automatically, the user code doesn't need to worry about this.

=ATTRIBUTES

=head2 C<@.postponed>

Queue of jobs postponed for later invocation. Not actually used by the manager itself except by C<await-all-jobs>
methods. Provided for consuming class code convenience.

=METHODS

=head2 C<test-job()>

A stub. Consuming class must provide it to report the maximum number of simultaneously executed jobs. See C<$.test-jobs>
attribute of L<C<Test::Async::Hub>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.4/docs/md/Test/Async/Hub.md>, for example.

=head2 C<job-count(--> Int)>

The total number of jobs in the job pool. Includes currently running ones.

=head2 C<new-job(Callable:D \code, :$async = False)>

Creates a new job instance of L<C<Test::Async::Job>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.4/docs/md/Test/Async/Job.md>
for C<code> parameter. C<$async> is used to mark the job as explicitly asynchronous.

=head2 C<all-job-promises(--> Seq)>

Returns promises of all jobs except those not invoked yet.

=head2 C<active-job-promises(--> Seq)>

Returns promises of "active" jobs; i.e. those started with C<start-job> method and currently being executed. Note that
those, invoked using C<start> method won't be included into the list.

=head2 C<mutli release-job(Int:D $id)>
=head2 C<multi release-job(Test::Async::Job:D $job)>

Removes a job from the pool. Usually there is no need for user code to call it.

=head2 C<multi postpone(Callable:D \code, :$async = False)>
=head2 C<multi postpone(Test::Async::Job:D $job)>

Pushes a job into C<@.postpone> queue.

=head2 C<job-by-id(Int:D $id --> Test::Async::Job)>

Returns job object with C<$id> or throws C<X::NoJobId>.

=head2 C<multi start-job(Int:D $id --> Promise)>
=head2 C<multi start-job(Callable \code --> Promise)>
=head2 C<multi start-job(Test::Async::Job:D $job --> Promise)>

If there are fewer running jobs than C<test-jobs> then method starts the job asynchronously. Otherwise the job is put on
the waiting queue. As soon as active jobs complete, the next job on the waiting queue gets defrost and invoked.

=head2 C<multi start(Int:D $id --> Promise)>
=head2 C<multi start(Callable:D \code --> Promise)>
=head2 C<multi start(Test::Async::Job:D $job --> Promise)>

Similarly to Raku's C<start> statement, this method starts a job instantly in a new thread. The difference though is
that a job started with this method is a subject for awaiting with C<await-all-jobs> method and is auto-removed from
the job pool when completed.

Jobs started with this method are not limited with C<test-jobs> value. Neither their're accounted by C<start-job>
method.

=head2 C<multi invoke-job(Int:D $id --> Promise)>
=head2 C<multi invoke-job(Test::Async::Job:D $job --> Promise)>

Invokes a job instantly. If job is marked as C<async> then it is started with C<start> method, listed above. Otherwise
job code is invoked instantly in the current thread.

Returns a L<C<Promise>|https://docs.raku.org/type/Promise> kept with job code return value.

=head2 C<await-all-jobs()>

Awaits for all running jobs to complete. If there are pending ones they'd be awaited too. The method returns when the
job pool is emptied.

Note that if the method encounters non-empty queue of postponed jobs it throws C<X::AwaitWithPostponed>. This is because
any exiting postponed job would likely cause the job pool to remain non-empty forever.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.4/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Job>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.4/docs/md/Test/Async/Job.md>,
L<C<Test::Async::X>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.4/docs/md/Test/Async/X.md>

=AUTHOR Vadim Belman <vrurg@lflat.org>

=end pod

unit role Test::Async::JobMgr;
use Test::Async::Job;
use Test::Async::X;

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

method test-jobs {...}

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
multi method start-job(Int:D $id) {
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
