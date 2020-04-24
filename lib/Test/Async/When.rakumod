use v6;

=begin pod
=NAME

C<Test::Async::When> - add C<:when> key to plan

=SYNOPSIS

Whole top suite:

    use Test::Async <When Base>;
    plan :when(<release>);

Or a subtest only:

    use Test::Async <When Base>;
    subtest "Might be skipped" => {
        plan :when(
                :all(
                    :any(<release author>),
                    :module<Optional::Module>));
        ...
    }
}

=DESCRIPTION

This bundle extends C<plan> with additional parameter C<:when> which defines when the suite is to be actually ran. If
C<when> condition is not fulfilled the suite is skipped. The condition is a nested combination of keys and values:

=item a string value means a name of a testing mode enabled with an environment variable. Simply put, it gets
uppercased, appended with I<_TESTING> and the resulting name is checked against C<%*ENV>. If the string is already
ending with I<_TESTING> it is used as-is.
=item a pair with C<env> key tests for a environment variable. The variable name is used as-is, with no manipulations
done to it.
=item a pair with C<module> key tests if a module with the given name is available
=item a pair with keys C<any> or C<all> basically means that either any of it subcondition or all of them are to be
fulfilled
=item a pair with C<none> key means all of its sunconditions must fail.

By default the topmost condition means C<any>, so that the following two statements are actually check the same
condition:

    plan :when<release author>;
    plan :when(:any<release author>);

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.6/docs/md/Test/Async/Manual.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

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
    X::WhenCondition.new(:suite($*TEST-SUITE), :cond(%cond.keys)).throw
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
