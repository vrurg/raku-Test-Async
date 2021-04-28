use v6;
use Test::Async::Decl;

=begin pod
=NAME

C<Test::Async::Reporter::TAP> - TAP reporter bundle

=DESCRIPTION

Maps events into TAP output.

The class is implementation detail. In addition to methods required by
L<C<Test::Async::Reporter>|https://github.com/vrurg/raku-Test-Async/blob/v0.1.900/docs/md/Test/Async/Reporter.md>,
also defines C<TAP-str-from-ev>.

=end pod

unit test-reporter Test::Async::Reporter::TAP;

use Test::Async::Event;
use Test::Async::Utils;

has @!lines;

method !diag-line(Str:D $message) {
    $message.split("\n")
            .map( '# ' ~ *)
            .join("\n");
}

proto method TAP-str-from-ev(::?CLASS:D: Event::Report:D, | --> Str) {*}

multi method TAP-str-from-ev(::?CLASS:D: Event::Ok:D $ev)    { self.TAP-str-from-ev($ev, <ok>) }

multi method TAP-str-from-ev(::?CLASS:D: Event::NotOk:D $ev) {
    my $caller = $ev.caller;
    my %profile;
    unless $.transparent {
        my $message = $ev.message;
        my $diag =
            self!diag-line( $message
                                ?? "Failed test '$message'\nat $caller.file() line $caller.line()"
                                !! "Failed test at $caller.file() line $caller.line()");
        %profile<message-postfix> = "\n" ~ $diag;
    }
    self.TAP-str-from-ev: $ev, 'not ok', |%profile
}

multi method TAP-str-from-ev(::?CLASS:D: Event::Skip:D $ev)  {
    self.TAP-str-from-ev($ev, 'ok', :message-prefix("# SKIP "))
}

multi method TAP-str-from-ev(::?CLASS:D: Event::Diag:D $ev)  {
    self!diag-line($ev.message);
 }

multi method TAP-str-from-ev(::?CLASS:D: Event::Plan:D $ev)  {
    # say "event plan of ", $ev.planned;
    my $message = "1.." ~ $ev.planned;
    if $ev.skip && !self.parent-suite {
        $message ~= " # Skipped: " ~ $ev.message
    }
    # say "plan message: $message";
    $message
}

multi method TAP-str-from-ev(::?CLASS:D: Event::DoneTesting:D $ev) {
    my @summary;
    if $.planned && $.tests-run != $.planned {
        @summary.push: "# You planned $.planned test"
                        ~ ($.planned == 1 ?? '' !! 's')
                        ~ ", but ran $.tests-run";
    }
    if $.tests-failed {
        @summary.push: "# You failed $.tests-failed test"
                        ~ ($.tests-failed == 1 ?? '' !! 's')
                        ~ " of $.tests-run";
    }
    @summary ?? @summary.join("\n") !! Nil
}

multi method TAP-str-from-ev(::?CLASS:D: Event::BailOut $ev) {
    join ' ', 'Bail out!', ($ev.message if $ev.message);
}

multi method TAP-str-from-ev(::?CLASS:D: Event::Test:D $ev, Str:D $kind,
                             Str:D :$message-prefix = "", Str:D :$message-postfix = "")
{
    my $prepend = "";
    my $comment = "";
    # say "< FROM EVENT ", $ev.^name, " -- “{$ev.message}”";
    if $ev.pre-comments {
        $prepend ~= self!diag-line($ev.pre-comments.join("\n")) ~ "\n";
    }
    if $ev.child-messages.elems {
        # Event source is a child, take its collected messages and nest them with spaces.
        $prepend ~= self.indent-message($ev.child-messages).join;
    }
    if $ev.comments {
        # note "IN TAP: ", $ev.comments.raku;
        $comment = "\n" ~ self!diag-line($ev.comments.join("\n"));
    }
    my $TODO = ($ev.todo andthen " # TODO " ~ $_);
    my $message = $message-prefix
                  ~ $ev.message.split(qw<\\ #>).map({ ++$ % 2 ?? $_ !! "\\" ~ $_ })
                  ~ $TODO
                  ~ $message-postfix;
    $prepend ~ $kind ~ " " ~ self.next-test-id ~ " - " ~ $message ~ $comment;
}

method report-event(Event::Report:D $ev) {
    my $bail-out = False;
    if $ev ~~ Event::BailOut {
        self.set-stage(TSDismissed);
        with self.parent-suite {
            # Don't report bail-out, hand it over to the parent.
            .send: Event::BailOut, :message($ev.message);
            return;
        }
        else {
            $bail-out = True;
        }
    }
    with self.TAP-str-from-ev($ev) {
        self.send-message: $_;
    }
    exit 255 if $bail-out;
}

# Expects a normalized message as input
method indent-message(+@message, Str:D :$prefix = $.nesting-prefix, Int:D :$nesting = 1 --> Seq:D) {
    my $pfx = $prefix x $nesting;
    # say ">indent by $nesting with “$prefix”";
    @message.map( $pfx ~ * )
}

# Excpects a normalized message as input. A message is considered as a whole. Thus, to guarantee atomic output
# operation, it is safer to join it into a single string.
method message-to-console(+@message) {
    my $out-str = ($.nesting ?? self.indent-message(@message, :$.nesting) !! @message).join;
    # self.trace-out: ">>> MESSSAGE from [" ~ self.id.fmt('%5d') ~ "]\n", $out-str, "\n>>> END OF MESSAGE\n";
    print $out-str;
}
