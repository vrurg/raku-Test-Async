use v6;

=begin pod
=NAME 

C<Test::Async::Metamodel::BundleClassHOW> - metaclass backing custom bundle classes.

=DESCRIPTION

This class function is to ensure that test tool methods are wrapped into common boilerplate. The boilerplate does
the following:

=item determines calling context to make sure any error reported points at user code where the test tool is invoked.
As a result it sets two dynamic variables
=item2 C<$*TEST-THROWS-LIKE-CTX> – L<C<Stash>|https://docs.raku.org/type/Stash> for test tools using EVAL.
=item2 C<$*TEST-CALLER> - L<C<CallerFrame>|https://docs.raku.org/type/CallerFrame> instance of the frame where the tool is invoked.
=item validates if current suite stage allows test tool invokation
=item tries to transition the suite into C<TSInProgress> stage if tool method object has `$.readify` set (see
L<C<Test::Async::TestTool>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/TestTool.md>
=item emits C<Event::Skip> if tool method has its C<$.skippable> set and suite's C<$.skip-message> is defined.
=item otherwise invokes the original test tool method code.

Note that wrapping doesn't replace the method object itself.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.0.5/docs/md/Test/Async/Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit class Test::Async::Metamodel::BundleClassHOW is Metamodel::ClassHOW;
use nqp;
use Test::Async::Event;
use Test::Async::Utils;
use Test::Async::TestTool;

method publish_method_cache(Mu \type-obj) {
    for type-obj.^methods.grep(Test::Async::TestTool) -> &meth is raw {
        my $name = &meth.tool-name;
        my \meth-do = nqp::getattr(&meth, Code, '$!do');

        # Test tool boilerplate wrapper.
        my &wrap := my method (|) is hidden-from-backtrace is raw {
            my \capture = nqp::usecapture();

            # Determine the caller and the context
            my $skip-frames = 1;
            # Don't make tests guess what is our caller's context.
            my $*TEST-THROWS-LIKE-CTX = CALLER::;
            while $*TEST-THROWS-LIKE-CTX<LEXICAL>.WHO<::?PACKAGE>.^name.starts-with('Test::Async') {
                ++$skip-frames;
                $*TEST-THROWS-LIKE-CTX = $*TEST-THROWS-LIKE-CTX<CALLER>.WHO;
            }
            my $*TEST-CALLER = callframe($skip-frames);

            if self.stage >= TSFinished {
                warn "A test tool called after done-testing at " ~ $*TEST-CALLER.gist;
                return;
            }
            self.set-stage(TSInProgress) if &meth.readify;
            if &meth.skippable && $.skip-message {
                self.send-test: Event::Skip, $.skip-message, TRSkipped;
                True
            }
            else {
                self.measure-telemetry: {
                    nqp::invokewithcapture(meth-do, capture)
                }
            }
        };

        &wrap.set_name(&meth.name);
        nqp::bindattr(&wrap, Code, '$!signature', &meth.signature.clone);
        my \wrap-do = nqp::getattr(&wrap, Code, '$!do');
        nqp::setcodeobj(wrap-do, &meth);
        nqp::bindattr(&meth, Code, '$!do', wrap-do);
    }
    nextsame;
}
