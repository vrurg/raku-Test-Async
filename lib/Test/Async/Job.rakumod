use v6;


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
