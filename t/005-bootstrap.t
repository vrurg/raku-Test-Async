use v6;
use nqp;
use lib $?FILE.IO.parent(1).add('lib');
use Test::Bootstrap;

# Make sure the most basic test tools work. With them we can launch the rest of the tests.

plan 12;

# Make subprocesses report errors in clear text.
%*ENV<RAKUDO_ERROR_COLOR> = 0;

sub wrap-code(Str:D $code) {
    'use lib "' ~ $?FILE.IO.parent(2).add('lib') ~ '"; use Test::Async;' ~ $code ~ '; done-testing'
}

is-run wrap-code(q<pass "pass works">),
    "we can use pass",
    :out("ok 1 - pass works\n1..1\n");
is-run wrap-code(q<flunk "flunk works">),
    "we can use flunk",
    :exitcode(1),
    :out("not ok 1 - flunk works\n# Failed test 'flunk works'\n# at - line 1\n1..1\n# You failed 1 test of 1\n");
is-run wrap-code(q<ok 2 == 2, "ok works">),
    "we can use ok with true expressions",
    :out("ok 1 - ok works\n1..1\n");
is-run wrap-code(q<ok 2 == 3, "ok works">),
    "we can use ok with false expressions",
    :exitcode(1),
    :out("not ok 1 - ok works\n# Failed test 'ok works'\n# at - line 1\n1..1\n# You failed 1 test of 1\n");
is-run wrap-code(q<nok 2 == 3, "nok works">),
    "we can use nok with false expressions",
    :exitcode(0),
    :out("ok 1 - nok works\n1..1\n");
is-run wrap-code(q<nok 2 == 2, "nok works">),
    "we can use nok with true expressions",
    :exitcode(1),
    :out(/^"not ok 1 - nok works\n# Failed test 'nok works'\n"/);
is-run wrap-code(q<cmp-ok 2, '==', 2, "cmp-ok works for ==">),
    "we can use cmp-ok with ==",
    :out("ok 1 - cmp-ok works for ==\n1..1\n");
is-run wrap-code(q<cmp-ok 2, '==', 3, "cmp-ok with == fails for non-equal values">),
    "cmp-ok fails on inequals with ==",
    :exitcode(1),
    :out("not ok 1 - cmp-ok with == fails for non-equal values\n# Failed test 'cmp-ok with == fails for non-equal values'\n# at - line 1\n# expected: 3\n#      got: 2\n#  matcher: infix:<==>\n1..1\n# You failed 1 test of 1\n");
is-run wrap-code(q<cmp-ok "abc", '~~', /\w+/, "cmp-ok works for smartmatch">),
    "we can use cmp-ok with ~~",
    :out("ok 1 - cmp-ok works for smartmatch\n1..1\n");
is-run wrap-code(q<cmp-ok "foo", '~~', /\d+/, "cmp-ok fails when no regex match">),
    :exitcode(1),
    "cmp-ok fails for non-matching regex",
    :out("not ok 1 - cmp-ok fails when no regex match\n# Failed test 'cmp-ok fails when no regex match'\n# at - line 1\n# expected: /\\d+/\n#      got: \"foo\"\n#  matcher: infix:<~~>\n1..1\n# You failed 1 test of 1\n");

%*ENV<RAKULIB> = ~$?FILE.IO.parent(2).add('lib');
%*ENV<PERL6LIB> = ~$?FILE.IO.parent(2).add('lib');
is-run wrap-code(q<is-run 'use Test::Async; pass "code ran"', "is-run with pass", :out("ok 1 - code ran\\n1..1\\n"), :err('');>),
        "we can use is-run",
        :out("  1..3\n  ok 1 - STDOUT\n  ok 2 - STDERR\n  ok 3 - Exit code\nok 1 - is-run with pass\n1..1\n");
is-run wrap-code(q<is-run 'use Test::Async; flunk "failing test"', "is-run with pass", :exitcode(1), :out(/:s^not ok 1 \- failing test\n/), :err('');>),
        "we can use is-run",
        :out("  1..3\n  ok 1 - STDOUT\n  ok 2 - STDERR\n  ok 3 - Exit code\nok 1 - is-run with pass\n1..1\n");

done-testing;
