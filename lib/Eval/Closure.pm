package Eval::Closure;
use strict;
use warnings;
use Sub::Exporter -setup => {
    exports => [qw(eval_closure)],
    groups  => { default => [qw(eval_closure)] },
};

use Carp;
use overload ();
use Scalar::Util qw(reftype);
use Try::Tiny;

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

    my ($compiler, $e) = _make_compiler(@_);
    my $code;
    if (defined $compiler) {
        $code = $compiler->(map { $captures->{$_} } sort keys %$captures);
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

sub _make_compiler_source {
    my ($source, $captures) = @_;
    my $i = 0;
    return join "\n", (
        'sub {',
        (map {
            'my ' . $_ . ' = ' . substr($_, 0, 1) . '{$_[' . $i++ . ']};'
         } sort keys %$captures),
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

1;
