use v6;


unit class Test::Async::Metamodel::BundleClassHOW is Metamodel::ClassHOW;
use Test::Async::Event;
use Test::Async::Utils;
use Test::Async::TestTool;

method !wrap-test-tools(Mu \type-obj) {
    for type-obj.^methods(:local).grep(Test::Async::TestTool) -> &meth is raw {
        next unless &meth.wrappable;

        # Test tool boilerplate wrapper.
        my $wrappee;
        my &wrapper := my method (|c) is hidden-from-backtrace is raw {
            $wrappee := nextcallee if IS-NEWDISP-COMPILER;

            # Don't even try invoking a test tool if the whole suite is doomed. This includes doomed parent suite too.
            return Nil if self.in-fatality;

            my ToolCallerCtx:D $tctx = self.locate-tool-caller(1, |(:anchored if &meth.anchoring));

            self.jobify-tool: {
                self.push-tool-caller: $tctx;
                LEAVE self.pop-tool-caller;

                if self.stage >= TSFinished {
                    warn "A test tool `{&meth.tool-name}` called after done-testing at " ~ $.tool-caller.frame.gist
                        ~ "\n  arguments: " ~ c.gist;
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

                $rc
            }
        };

        if IS-NEWDISP-COMPILER {
            # .wrap works on new-disp
            &wrapper.set_name(&meth.name);
            &meth.wrap: &wrapper;
        }
        else {
            use nqp;
            $wrappee := nqp::getattr(&meth, Code, '$!do');

            &wrapper.set_name(&meth.name);
            nqp::bindattr(&wrapper, Code, '$!signature', &meth.signature.clone);
            my \wrap-do = nqp::getattr(&wrapper, Code, '$!do');
            nqp::setcodeobj(wrap-do, &meth);
            nqp::bindattr(&meth, Code, '$!do', wrap-do);
        }
    }
}

method publish_method_cache(Mu \type-obj) {
    self!wrap-test-tools(type-obj);
    nextsame
}
