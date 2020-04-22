use v6;

=begin pod
=end pod

use Test::Async::Decl;
our test-bundle Test::Async::When {
    use Test::Async::X;

    has Str $.when-skip-message;

    my class FalseMsg {
        has Str:D $.message is required;
        method Bool { False }
    }

    my proto _testcond(|) {*}
    multi _testcond(List() :$any!) {
        my @cond-failures;
        for |$any -> $cond {
            my $res = _testcond(|$cond);
            return True if $res;
            @cond-failures.push: $res;
        }
        my $message = @cond-failures == 1
                        ?? @cond-failures.head.message
                        !! "any(" ~ @cond-failures.map( *.message ).join(", ") ~ ")";
        FalseMsg.new(:$message)
    }
    multi _testcond(List() :$all!) {
        for |$all -> $cond {
            my $res = _testcond(|$cond);
            return $res unless $res;
        }
        True
    }
    multi _testcond(Str(Any:D) :$env) {
        my $env-var = $env.ends-with('_TESTING') ?? $env !! $env.uc ~ '_TESTING';
        return FalseMsg.new(:message('$' ~ $env-var)) unless %*ENV{$env-var}:exists;
        True
    }
    multi _testcond(Str(Any:D) :$module) {
        my $mod := ::($module);
        if $mod ~~ Failure {
            $mod.so;
            my $load-failed = (Nil =:= try { require ::($module) });
            return FalseMsg.new(:message("module(" ~ $module ~ ")")) if $load-failed;
        }
        True
    }
    multi _testcond(Stringy:D $env) {
        _testcond(:$env)
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
        _testcond(:any(@env, |%cond))
    }
}

package EXPORT::DEFAULT {
    # for <AUTHOR AUTOMATED EXTENDED NONINTERACTIVE RELEASE> -> $kwd {
    #     my &tsub = sub () { &testing-env($kwd) };
    #     my $sub-name = '&testing-' ~ $kwd.lc;
    #     &tsub.set_name($sub-name);
    #     ::?PACKAGE.WHO{ $sub-name } = &tsub;
    # }
}
