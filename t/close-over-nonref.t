#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Eval::Closure;

my $number  = 40;
my $closure = eval_closure(
	source       => 'sub { $xxx += 2 }',
	environment  => { '$xxx' => \$number },
	alias        => 1,
);

$closure->();

is($number, 42);

done_testing;
