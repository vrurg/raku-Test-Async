use v6;
use nqp;
unit class Test::Async::Metamodel::BundleClassHOW is Metamodel::ClassHOW;
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
                self.skip: $.skip-message
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
