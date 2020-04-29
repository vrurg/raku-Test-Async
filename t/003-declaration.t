use v6;
use lib $?FILE.IO.parent(1).add('lib');
use Test::Bootstrap;
use Test::Async::Decl;
use Test::Async::Event;
use Test::Async::Metamodel::BundleHOW;
use Test::Async::Metamodel::ReporterHOW;

plan 2;

test-bundle MyBundle {
    my role RB { }
    method get_role { RB }
}

test-reporter MyReporter {
    my role RR { }
    method get_role { RR }
    method report-event(Event:D) { }
    method indent-message(+@, *% --> Array()) { }
    method message-to-console(+@) { }
}

ok MyBundle.^candidates[0].HOW ~~ Test::Async::Metamodel::BundleHOW, "bundle's HOW is BundleHOW";
ok MyBundle.get_role.^candidates[0].HOW ~~ Metamodel::ParametricRoleHOW, "role created inside a bundle has standard HOW";
ok MyReporter.^candidates[0].HOW ~~ Test::Async::Metamodel::ReporterHOW, "reporter's HOW is ReporterHOW";
ok MyReporter.get_role.^candidates[0].HOW ~~ Metamodel::ParametricRoleHOW, "role created inside a reporter has standard HOW";

done-testing;
