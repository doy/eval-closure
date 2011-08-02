#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Eval::Closure;

my $code = eval_closure(
    source => 'no strict "refs"; sub { keys %{__PACKAGE__ . "::"} }',
);

# defining the sub { } creates __ANON__, calling 'no strict' creates BEGIN
my @stash_keys = grep { $_ ne '__ANON__' && $_ ne 'BEGIN' } $code->();

is_deeply([@stash_keys], [], "compiled in an empty package");

done_testing;
