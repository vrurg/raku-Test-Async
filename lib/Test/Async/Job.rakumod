use v6;
unit class Test::Async::Job;

has Int:D $.id = ++$;
has Callable:D $.code is required;
# async indicated if job is explictly requested to be async.
has $.async = False;
has Promise $.promise;

method start {
    $!promise = start $!code()
}

method invoke {
    my $vow = ($!promise = Promise.new).vow;
    $vow.keep: $!code();
    $!promise
}

method is-started   { $!promise.defined }
method is-completed { $!promise andthen .status ne Planned }
