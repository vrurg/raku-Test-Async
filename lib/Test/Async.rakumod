use v6;
use Test::Async::Metamodel::HubHOW;
use Test::Async::Hub;
use Test::Async::Reporter;
use Test::Async::TestTool;

=begin pod
=head1 NAME

C<Test::Async> - base module of the framework

=head1 SYNOPSIS

    use Test::Async;
    plan 1;
    pass "Hello World!";
    done-testing;

=head1 DESCRIPTION

=head2 Exports

=head3 C<test-suite>

Return the test suite which is actual for the current context. The suite is looked up either in C<$*TEST-SUITE> or
via C<Test::Async::Hub> C<top-suite> method.

=head3 Test Tools

The module export all test tools it finds in the top suite object. See
L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Manual.md>
for more details.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::CookBook>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.1/docs/md/Test/Async/CookBook.md>

=end pod

module Test::Async:ver<0.0.1> {
    our sub test-suite {
        once require ::('Test::Async::Hub');
        $*TEST-SUITE // ::('Test::Async::Hub').top-suite
    }
}

sub EXPORT(*@b) {
    my @bundles = (Test::Async::Hub.HOW.bundles, @b).flat;
    @bundles = (<Base>) unless @bundles;
    my $has-reporter;
    for Test::Async::Metamodel::HubHOW.bundles -> \bundle-class {
        if bundle-class ~~ Test::Async::Reporter {
            $has-reporter = True;
            last;
        }
    }
    @bundles.push: 'Test::Async::Reporter::TAP' unless $has-reporter;
    for @bundles.grep(Str) {
        my $bundle = .index('::') ?? $_ !! 'Test::Async::' ~ $_;
        require ::($bundle);
    }
    Map.new(
        |Test::Async::Hub.tool-factory,
        '&test-suite' => &Test::Async::test-suite,
    )
}

END {
    if Test::Async::Hub.has-top-suite {
        my $hub = Test::Async::Hub.top-suite;
        Test::Async::Hub.top-suite.done-testing;
        my $exit-code = $hub.tests-failed min 254;
        unless $exit-code {
            $exit-code = 255
                if ($hub.planned.defined && $hub.tests-run) && (($hub.planned // 0) != ($hub.tests-run // 0));
        }
        exit $exit-code;
    }
}
