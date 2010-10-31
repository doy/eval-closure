package Eval::Closure;
use strict;
use warnings;
use Sub::Exporter -setup => {
    exports => [qw(eval_closure)],
    groups  => { default => [qw(eval_closure)] },
};
# ABSTRACT: safely and cleanly create closures via string eval

use Carp;
use overload ();
use Memoize;
use Scalar::Util qw(reftype);
use Try::Tiny;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=func eval_closure(%args)

=cut

sub eval_closure {
    my (%args) = @_;

    $args{source} = _canonicalize_source($args{source});
    _validate_env($args{environment} ||= {});

    $args{source} = _line_directive($args{description}) . $args{source}
        if defined $args{description};

    my ($code, $e) = _clean_eval_closure(@args{qw(source environment)});

    croak("Failed to compile source: $e\n\nsource:\n$args{source}")
        unless $code;

    return $code;
}

sub _canonicalize_source {
    my ($source) = @_;

    if (defined($source)) {
        if (ref($source)) {
            if (reftype($source) eq 'ARRAY'
             || overload::Method($source, '@{}')) {
                return join "\n", @$source;
            }
            elsif (overload::Method($source, '""')) {
                return "$source";
            }
            else {
                croak("The 'source' parameter to eval_closure must be a "
                    . "string or array reference");
            }
        }
        else {
            return $source;
        }
    }
    else {
        croak("The 'source' parameter to eval_closure is required");
    }
}

sub _validate_env {
    my ($env) = @_;

    croak("The 'environment' parameter must be a hashref")
        unless reftype($env) eq 'HASH';

    for my $var (keys %$env) {
        croak("Environment key '$var' should start with \@, \%, or \$")
            unless $var =~ /^([\@\%\$])/;
        croak("Environment values must be references, not $env->{$var}")
            unless ref($env->{$var});
    }
}

sub _line_directive {
    my ($description) = @_;

    return qq{#line 1 "$description"\n};
}

sub _clean_eval_closure {
     my ($source, $captures) = @_;

    if ($ENV{EVAL_CLOSURE_PRINT_SOURCE}) {
        _dump_source(_make_compiler_source(@_));
    }

    my @capture_keys = sort keys %$captures;
    my ($compiler, $e) = _make_compiler($source, @capture_keys);
    my $code;
    if (defined $compiler) {
        $code = $compiler->(@$captures{@capture_keys});
    }

    if (defined($code) && (!ref($code) || ref($code) ne 'CODE')) {
        $e = "The 'source' parameter must return a subroutine reference, "
           . "not $code";
        undef $code;
    }

    return ($code, $e);
}

sub _make_compiler {
    local $@;
    local $SIG{__DIE__};
    my $compiler = eval _make_compiler_source(@_);
    my $e = $@;
    return ($compiler, $e);
}
memoize('_make_compiler');

sub _make_compiler_source {
    my ($source, @capture_keys) = @_;
    my $i = 0;
    return join "\n", (
        'sub {',
        (map {
            'my ' . $_ . ' = ' . substr($_, 0, 1) . '{$_[' . $i++ . ']};'
         } @capture_keys),
        $source,
        '}',
    );
}

sub _dump_source {
    my ($source) = @_;

    my $output;
    if (try { require Perl::Tidy }) {
        Perl::Tidy::perltidy(
            source      => \$source,
            destination => \$output,
        );
    }
    else {
        $output = $source;
    }

    warn "$output\n";
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-eval-closure at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Eval-Closure>.

=head1 SEE ALSO

=over 4

=item * L<Class::MOP::Method::Accessor>

This module is a factoring out of code that used to live here

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Eval::Closure

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Eval-Closure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Eval-Closure>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Eval-Closure>

=item * Search CPAN

L<http://search.cpan.org/dist/Eval-Closure>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

Based on code from L<Class::MOP::Method::Accessor>, by Stevan Little and the
Moose Cabal.

=cut

1;
