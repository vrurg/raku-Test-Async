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
L<C<Test::Async::TestTool>|../TestTool.md>
=item emits C<Event::Skip> if tool method has its C<$.skippable> set and suite's C<$.skip-message> is defined.
=item otherwise invokes the original test tool method code.

Wrapping doesn't replace the method object itself.

If test tool method object has its C<wrappable> attribute set to I<False> then wrapping doesn't take place. In this case
the method must take care of all necessary preparations itself. See implementation of C<subtest> by
L<C<Test::Async::Base>|../Base.md> for example.

=head1 SEE ALSO

L<C<Test::Async::Manual>|../Manual.md>,
L<C<Test::Async::Decl>|../Decl.md>

=AUTHOR Vadim Belman <vrurg@cpan.org>

=end pod

unit class Test::Async::Metamodel::BundleClassHOW is Metamodel::ClassHOW;
use Test::Async::Event;
use Test::Async::Utils;
use Test::Async::TestTool;
use MONKEY-SEE-NO-EVAL;

method !wrap-test-tools(Mu \type-obj) {
    for type-obj.^methods(:local).grep(Test::Async::TestTool) -> &meth is raw {
        next unless &meth.wrappable;
        if $*RAKU.compiler.version >= v2021.09.228.gdd.2.b.274.fd {
            # .wrap works on new-disp
            my &wrapper := my method (|c) is hidden-from-backtrace is raw {
                my $wrappee := nextcallee;
                # Don't even try invoking a test tool if the whole suite is doomed. This includes doomed parent suite too.
                return if self.in-fatality;

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
                        $rc = $wrappee(self, |c);
                    }
                }
                self.pop-tool-caller;
                $rc
            };
            &wrapper.set_name(&meth.name);
            &meth.wrap: &wrapper;
        }
        else {
            # Code for older Rakudo compilers has to be wrapped into EVAL because new-disp doesn't have
            # nqp::invokewithcapture and fails to compile whatsoever
            EVAL q:to/WRAP_END/;
                    use nqp;
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
                    WRAP_END
        }
    }
}

method publish_method_cache(Mu \type-obj) {
    self!wrap-test-tools(type-obj);
    nextsame
}
