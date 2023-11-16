use v6;


use Test::Async::Decl;
unit test-bundle Test::Async::When;
use Test::Async::X;

has Str $.when-skip-message;

my class FalseMsg {
    has Str:D $.message is required;
    method Bool { False }
}

# Takes condition, inverses it if requested so by $*TESTCOND-INV, and returns either True or FalseMsg isntance
my sub _testcond_so(Bool(Any:D) $cond, $message) {
    ?($cond ^^ ?$*TESTCOND-NOT) || FalseMsg.new(:$message)
}

my %not-translate = :any<all>, :all<any>;
my proto _testcond_maybe_inv(|c) {*}
multi _testcond_maybe_inv(Pair:D $cond) {
    my $cond_op = $cond.key;
    my $is-not = $*TESTCOND-NOT;
    my $msg_op = $cond_op if $cond_op ~~ 'all' | 'any' | 'none';
    if $cond_op eq 'none' {
        $is-not = ! $is-not;
        $cond_op = $is-not ?? 'all' !! 'any';
    }
    elsif $is-not && $cond_op eq any('all', 'any') {
        $cond_op = $cond_op eq 'all' ?? 'any' !! 'all';
    }
    temp $*TESTCOND-NOT = $is-not;
    # note "== not: ", $is-not, ", op=(", $cond.key, " => ", $cond_op, ")";
    my $*TESTCOND-NOWRAP-MSG = False;
    my $res = _testcond(|($cond_op => $cond.value));
    # note "WRAP? ", $*TESTCOND-NOWRAP-MSG;
    unless $res || $*TESTCOND-NOWRAP-MSG || !$msg_op {
        $res = FalseMsg.new(:message($msg_op ~ "(" ~ $res.message ~ ")"));
    }
    $res
}
multi _testcond_maybe_inv(Stringy:D $alias) {
    my $env = $alias.ends-with('_TESTING') ?? $alias !! $alias.uc ~ '_TESTING';
    _testcond(:$env)
}

my proto _testcond(|) {*}
multi _testcond(List() :$any!) {
    my @cond-failures;
    for $any.flat -> $cond {
        my $res = _testcond_maybe_inv($cond);
        return True if $res;
        @cond-failures.push: $res;
    }
    $*TESTCOND-NOWRAP-MSG = +@cond-failures == 1;
    FalseMsg.new(message => @cond-failures.map( *.message ).join(", "))
}
multi _testcond(List() :$all!) {
    my $res = True;
    for $all.flat -> $cond {
        $res = _testcond_maybe_inv($cond);
        last unless $res;
    }
    # note "---- all";
    $*TESTCOND-NOWRAP-MSG = !$*TESTCOND-NOT;
    $res
}
multi _testcond(Str(Any:D) :$env) {
    _testcond_so( %*ENV{$env}:exists, '$' ~ $env );
}
multi _testcond(Str(Any:D) :$module) {
    my $mod := ::($module);
    my $load-succeed = True;
    if $mod ~~ Failure {
        $mod.so;
        $load-succeed = ! (Nil =:= try { require ::($module) });
    }
    _testcond_so($load-succeed, "module(" ~ $module ~ ")")
}
multi _testcond(*%cond) {
    # We expect only one named parameter here
    Test::Async::X::WhenCondition.new(:suite($*TEST-SUITE), :cond(%cond.keys)).throw
        if %cond;
}

method setup-from-plan(%plan) {
    if %plan<when>:exists {
        my $cond := self.test-requires( |(%plan<when>:delete) );
        unless $cond {
            unless %plan<skip-all>:exists {
                %plan<skip-all> = "Unfulfilled when condition: " ~ $cond.message;
            }
        }
    }
    callsame;
}

proto method test-requires(|) is test-tool(:!skippable, :!readify) {*}
multi method test-requires(*@env, *%cond) {
    my $*TESTCOND-NOT = False;
    my $*TESTCOND-NOWRAP-MSG = False;
    _testcond(:any(@env, |%cond))
}
