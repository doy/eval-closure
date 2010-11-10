#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::Output';

use Eval::Closure;

{
    my $code = eval_closure(
        source      => 'sub { warn "foo" }',
        description => 'bar',
    );
    { local $TODO = $] < 5.010 ? "line numbers from #line are slightly different" : undef;
    stderr_is { $code->() } "foo at bar line 1.\n", "got the right line";
    }
}

{
    my $code = eval_closure(
        source      => <<'SOURCE',
    sub {

        warn "foo";

    }
SOURCE
        description => 'bar',
    );
    { local $TODO = $] < 5.010 ? "line numbers from #line are slightly different" : undef;
    stderr_is { $code->() } "foo at bar line 1.\n", "got the right line";
    }
}

{
    my $code = eval_closure(
        source      => <<'SOURCE',

    sub {
        warn "foo";
    }
SOURCE
        description => 'bar',
    );
    { local $TODO = $] < 5.010 ? "line numbers from #line are slightly different" : undef;
    stderr_is { $code->() } "foo at bar line 1.\n", "got the right line";
    }
}

{
    my $code = eval_closure(
        source      => '$sub',
        environment => { '$sub' => \sub { warn "foo" } },
        description => 'bar',
    );
    { local $TODO = $] < 5.010 ? "#line can't adjust line numbers inside non-evaled subs" : undef;
    stderr_is { $code->() } "foo at bar line 1.\n", "got the right line";
    }
}

done_testing;
