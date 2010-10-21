#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Eval::Closure;

use Test::Requires 'PadWalker';

{
    my $foo = [];
    my $env = { '$foo' => \$foo };

    my $code = eval_closure(
        source      => 'sub { push @$foo, @_ }',
        environment => $env,
    );
    is_deeply(scalar(PadWalker::closed_over($code)), $env,
              "closed over the right things");
}

{
    my $foo = {};
    my $bar = [];
    my $env = { '$foo' => \$bar, '$bar' => \$foo };

    my $code = eval_closure(
        source      => 'sub { push @$foo, @_; $bar->{foo} = \@_ }',
        environment => $env,
    );
    is_deeply(scalar(PadWalker::closed_over($code)), $env,
              "closed over the right things");
}

{
    my $foo = [];
    my $env = { '$foo' => \$foo };

    throws_ok {
        my $code = eval_closure(
            source      => 'sub { push @$foo, @_; return $__captures }',
            environment => $env,
        );
    } qr/Global symbol "\$__captures/, "we don't close over \$__captures";
}

# it'd be nice if we could test that closing over other things wasn't possible,
# but perl's optimizer gets in the way of that

done_testing;
