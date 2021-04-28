use v6;

=begin pod
=NAME

C<Test::Async::Metamodel::BundleClassHOW> - metaclass backing custom bundle classes.

=DESCRIPTION

This class purpose is to ensure that test tool methods are wrapped into common boilerplate. The boilerplate does
the following:

=item determines calling context to make sure any error reported points at user code where the test tool is invoked.
As a result it sets C<tool-caller> and C<caller-ctx> attributes of the current suite object.
=item validates if current suite stage allows test tool invokation
=item tries to transition the suite into C<TSInProgress> stage if tool method object has `$.readify` set (see
L<C<Test::Async::TestTool>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.0/docs/md/Test/Async/TestTool.md>
=item emits C<Event::Skip> if tool method has its C<$.skippable> set and suite's C<$.skip-message> is defined.
=item otherwise invokes the original test tool method code.

Wrapping doesn't replace the method object itself.

If test tool method object has its C<wrappable> attribute set to I<False> then wrapping doesn't take place. In this case
the method must take care of all necessary preparations itself. See implementation of C<subtest> by
L<C<Test::Async::Base>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.0/docs/md/Test/Async/Base.md> for example.

=head1 SEE ALSO

L<C<Test::Async::Manual>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.0/docs/md/Test/Async/Manual.md>,
L<C<Test::Async::Decl>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.0/docs/md/Test/Async/Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit class Test::Async::Metamodel::BundleClassHOW is Metamodel::ClassHOW;
use nqp;
use Test::Async::Event;
use Test::Async::Utils;
use Test::Async::TestTool;

method !wrap-test-tools(Mu \type-obj) {
    for type-obj.^methods.grep(Test::Async::TestTool) -> &meth is raw {
        next unless &meth.wrappable;
        my \meth-do = nqp::getattr(&meth, Code, '$!do');

        # Test tool boilerplate wrapper.
        my &wrap := my method (|) is hidden-from-backtrace is raw {
            # Don't even try invoking a test tool if the whole suite is doomed. This includes doomed parent suite too.
            return if self.in-fatality;

            my \capture = nqp::usecapture();

            self.push-tool-caller: self.locate-tool-caller(1, |(:anchored if &meth.anchoring));

            if self.stage >= TSFinished {
                warn "A test tool called after done-testing at " ~ $.tool-caller.frame.gist;
                return;
            }
            self.set-stage(TSInProgress) if &meth.readify;
            my $rc;
            if &meth.skippable && $.skip-message.defined {
                self.send-test: Event::Skip, $.skip-message, TRSkipped;
                $rc = True;
            }
            else {
                self.measure-telemetry: {
                    $rc = nqp::invokewithcapture(meth-do, capture)
                }
            }
            self.pop-tool-caller;
            $rc
        };

        &wrap.set_name(&meth.name);
        nqp::bindattr(&wrap, Code, '$!signature', &meth.signature.clone);
        my \wrap-do = nqp::getattr(&wrap, Code, '$!do');
        nqp::setcodeobj(wrap-do, &meth);
        nqp::bindattr(&meth, Code, '$!do', wrap-do);
    }
}

method publish_method_cache(Mu \type-obj) {
    self!wrap-test-tools(type-obj);
    nextsame
}
