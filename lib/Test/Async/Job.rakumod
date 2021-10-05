use v6;

=begin pod
=NAME

C<Test::Async::Job> - a job record task

=DESCRIPTION

Class defines a job entry for L<C<Test::Async::JobMgr>|JobMgr.md>.

=ATTRIBUTES

=head2 C<Int:D $.id>

Job ID number. Autoincerements.

=head2 C<Callable:D $.code>

User code to be executed.

=head2 C<Bool $.async>

If I<True> then the job must be executed asynchronously.

=head2 C<Promise $.promise>

Job completion promise. Undefined until the job is invoked. Set to a L<C<Promise>|https://docs.raku.org/type/Promise>
instance as soon as job starts execution and is kept with job code return value.

=METHODS

=head2 C<start(--> Promise:D)>

Starts job in a thread.

=head2 C<invoke(--> Promise:D)>

Starts job instantly in the current thread.

=head2 C<is-started(--> Bool)>

I<True> if job has been started.

=head2 C<is-completed(--> Bool)>

I<True> if job has completed.

=head1 SEE ALSO

L<C<Test::Async::JobMgr>|JobMgr.md>,
L<C<Test::Async::Hub>|Hub.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit class Test::Async::Job;

my atomicint $next-id = 0;
has Int:D $.id = $next-id⚛++;
has Callable:D $.code is required;
# async indicated if job is explictly requested to be async.
has $.async = False;
has Promise $.promise;

method start {
    $!promise = start $!code()
}

method invoke {
    my $vow = ($!promise = Promise.new).vow;
    CATCH {
        $vow.break: $_;
        .rethrow
    }
    $vow.keep: $!code();
    $!promise
}

method is-started   { $!promise.defined }
method is-completed { $!promise andthen .status ne Planned }
