#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Eval::Closure;

{
    my $source = 'sub { ++$foo }';

    {
        like(
            exception {
                eval_closure(source => $source);
            },
            qr/Global symbol "\$foo/,
            "errors with strict enabled"
        );
    }

    {
        no strict;
        my $c1;
        is(
            exception {
                $c1 = eval_closure(source => $source);
            },
            undef,
            "no errors with no strict"
        );
        is($c1->(), 1);
        is($c1->(), 2);
    }
}

{
    my $source = 'our $less; BEGIN { $less = $^H{less} } sub { $less }';

    {
        my $c1 = eval_closure(source => $source);
        is($c1->(), undef, "nothing in the hint hash");
    }

    {
        local $TODO = 'not sure how exactly to get %^H copied';
        use less "stuff";
        my $c1 = eval_closure(source => $source);
        is($c1->(), 'stuff', "use less put stuff in the hints hash");
    }
}

done_testing;
