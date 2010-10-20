#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Eval::Closure 'eval_closure';

my $foo = [];

my $code = eval_closure(
    source      => 'sub { push @$bar, @_ }',
    environment => {
        '$bar' => \$foo,
    },
    name        => 'test',
);
ok($code, "got something");

$code->(1);

is_deeply($foo, [1], "got the right thing");

done_testing;
