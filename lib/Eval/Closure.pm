package Eval::Closure;
use Sub::Exporter -setup => {
    exports => [qw(eval_closure)],
};

use Carp;
use overload ();
use Scalar::Util qw(reftype);
use Try::Tiny;

sub eval_closure {
    my (%args) = @_;
    $args{source} = _canonicalize_source($args{source});

    my ($code, $e) = _clean_eval_closure(@args{qw(source environment name)});

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

sub _clean_eval_closure {
    my $__captures = $_[1];

    do {
        local $@;
        local $SIG{__DIE__};

        if ($ENV{EVAL_CLOSURE_PRINT_SOURCE}) {
            _dump_source(_make_source(@_), $_[2]);
        }

        my $code = eval _make_source(@_);
        ($code, $@);
    };
}

sub _make_source {
    my ($source, $__captures) = @_;
    return join "\n", (
        (map {
            die "Capture key should start with \@, \% or \$: $_"
                unless /^([\@\%\$])/;
            'my ' . $_ . ' = ' . $1 . '{$__captures->{\'' . $_ . '\'}};';
        } keys %$__captures),
        $source,
    );
}

sub _dump_source {
    my ($source, $name) = @_;

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

    $name = defined($name) ? $name : "__ANON__";
    warn $name . ":\n" . $output . "\n";
}

1;
