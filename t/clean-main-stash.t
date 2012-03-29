#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Eval::Closure;

{
    my @keys_before = keys %::;

    my $sub = eval_closure(
        source      => 'sub { 1 }',
        description => 'foo',
    );

    is_deeply([sort keys %::], [sort @keys_before]);
}

{
    my @keys_before = keys %::;

    my $sub = eval_closure(
        source      => 'sub { 1 }',
        line        => 100,
    );

    is_deeply([sort keys %::], [sort @keys_before]);
}

{
    my @keys_before = keys %::;

    my $sub = eval_closure(
        source      => 'sub { 1 }',
        description => 'foo',
        line        => 100,
    );

    is_deeply([sort keys %::], [sort @keys_before]);
}

{
    my @keys_before = keys %::;

    my $sub = eval_closure(
        source      => 'sub { 1 }',
        description => __FILE__,
    );

    is_deeply([sort keys %::], [sort @keys_before]);
}

done_testing;
