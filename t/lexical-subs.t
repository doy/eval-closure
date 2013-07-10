#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::Requires '5.018';
use 5.018;

use Eval::Closure;

my $sub = eval_closure(
    source => 'sub { foo() }',
    environment => {
        '&foo' => sub { state $i++ },
    }
);

is($sub->(), 0);
is($sub->(), 1);
is($sub->(), 2);

done_testing;
