#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Symbol;

my $tests;

BEGIN { $tests += 1 }

require_ok  'Exporter::NoWork'
    or BAIL_OUT "can't load module";

my $PKG = 'TestAAAA';

## At what point do the tests become more complicated and less reliable
## than the code they're testing...?

sub import_ok {
    my ($mod, $args, $msg) = @_;
    my $tb  = Test::More->builder;

    my $code = "package $PKG; $mod->import(qw/$args/); 1";

    #$tb->diag($code);

    my $eval = eval $code;

    $tb->ok($eval, $msg) or $tb->diag(<<DIAG);
$mod->import(qw/$args/) failed:
$@
DIAG
}

sub import_nok {
    my ($mod, $args, $msg) = @_;
    my $tb  = Test::More->builder;

    my $eval = eval "package $PKG; $mod->import(qw/$args/); 1";

    $tb->ok(!$eval, $msg) or $tb->diag(<<DIAG);
$mod->import(qw/$args/) succeeded where it should have failed.
DIAG
}

sub is_import {
    my $msg  = pop;
    my $from = pop;
    my $tb = Test::More->builder;

    my @nok;

    for (@_) {
        my $to = "$PKG\::$_";

        no strict 'refs';
        unless (defined &$to) {
            push @nok, <<DIAG;
  \&$to is not defined
DIAG
            next;
        }

        \&$to == \&{"$from\::$_"} or push @nok, <<DIAG;
  \&$to is not imported correctly
DIAG
    }

    my $ok = $tb->ok(!@nok, $msg) or $tb->diag(<<DIAG);
Expected subs to be imported from $from:
DIAG
    $tb->diag($_) for @nok;
    return $ok;
}

sub cant_ok {
    my $msg = pop;
    my $tb  = Test::More->builder;

    my @nok;

    for (@_) {
        $PKG->can($_) and push @nok, $_;
    }

    my $ok = $tb->ok(!@nok, $msg);
    
    $tb->diag(<<DIAG) for @nok;
\&$PKG\::$_ should not exist.
DIAG

    return $ok;
}

## OK, now let's have some actual tests.

{
    package t::Basic;
    Exporter::NoWork->import;
    Exporter::NoWork->import;

    sub public   { 1; }
    sub _private { 1; }
    sub CAPS     { 1; }

    package t::Inherit;
    our @ISA = 't::Basic';
    Exporter::NoWork->import;
}

BEGIN { $tests += 4 }

can_ok  't::Basic',     'import';
ok(     t::Basic->isa('Exporter::NoWork'),  'inheritance is set up');

# [rt.cpan.org #33595]
is grep($_ eq 'Exporter::NoWork', @t::Basic::ISA), 1, '...but only once';
is_deeply \@t::Inherit::ISA, ['t::Basic'], '...even with inheritance';

BEGIN { $tests += 9 }

my @subs = qw/public _private CAPS import ALL/;
$_ = 'flirble';

import_ok   't::Basic', '',             'empty import list';
cant_ok     @subs,                      '...imports nothing';
# [rt.cpan.org #33584]
is          $_,         'flirble',      '...without clobbering $_';

import_ok   't::Basic', 'public',       'public sub imports';
is_import   'public',   't::Basic',     '...correctly';

import_ok   't::Basic', 'CAPS',         'CAPS sub imports';
is_import   'CAPS',     't::Basic',     '...correctly';

$PKG++;

import_ok   't::Basic', '&public',      'sub with & imports';
is_import   'public',   't::Basic',     '...correctly';

BEGIN { $tests += 9 }

import_nok  't::Basic', '_private',     '_private sub fails';
like        $@, qr/is not exported by/, '...correctly';
cant_ok     '_private',                 '...and isn\'t imported';

import_nok  't::Basic', 'notexist',     'nonexistant sub fails';
like        $@, qr/is not exported by/, '...correctly';
cant_ok     'notexist',                 '...and isn\'t imported';

import_nok  't::Basic', 'import',           '\'import\' fails';
like        $@, qr/Import methods can't/,   '...correctly';
cant_ok     'import',                       '...and doesn\'t import';

BEGIN { $tests += 4 }

import_nok  't::Basic', '-option',      '-option fails';
like        $@, qr/option.*not recog/,  '...correctly';

import_nok  't::Basic', ':tag',         ':tag fails';
like        $@, qr/Tag.*not recog/,     '...correctly';

BEGIN { $tests += 5 }

$PKG++;

import_ok   't::Basic', ':DEFAULT',     ':DEFAULT imports';
cant_ok     @subs,                      '...nothing';

import_ok   't::Basic', ':ALL',         ':ALL imports';
is_import   qw/public CAPS t::Basic/,   '...enough';
cant_ok     qw/_private import/,        '...but not too much';

{
    package t::Default;
    Exporter::NoWork->import(qw/default/);

    sub public   { 1; }
    sub default  { 1; }
    sub _private { 1; }
}

BEGIN { $tests += 12 }

$PKG++;

import_ok   't::Default',   '',             'blank import';
is_import   'default',      't::Default',   '...imports default';
cant_ok     qw/public _private/,            '...but no more';

$PKG++;

import_ok   't::Default',   'public',       'specified import';
is_import   'public',       't::Default',   '...imports correctly';
cant_ok     qw/default _private/,           '...without default';

$PKG++;

import_ok   't::Default',   ':DEFAULT',     ':DEFAULT import';
is_import   'default',      't::Default',   '...imports default';
cant_ok     qw/public _private/,            '...but no more';

$PKG++;

import_ok   't::Default',   ':DEFAULT public',
                                            ':DEFAULT+more import';
is_import   qw/public default t::Default/,  '...imports correctly';
cant_ok     qw/_private/,                   '...but no more';

eval q/
    package t::Tags;
    use Exporter::NoWork;

    sub public { 1; }
    sub tag1 :Tag(foo) { 1; }
    sub tag2 :Tag(foo) { 1; }
/;

BEGIN { $tests += 10 }

$PKG++;

import_ok   't::Tags',      '',             'blank import';
cant_ok     qw/public tag1 tag2/,           '...imports nothing';

$PKG++;

import_ok   't::Tags',      ':ALL',         ':ALL import';
is_import   qw/tag1 tag2 public t::Tags/,   '...imports correctly';

$PKG++;

import_ok   't::Tags',      ':foo',         'tagged import';
is_import   qw/tag1 tag2/,  't::Tags',      '...imports correctly';
cant_ok     qw/public/,                     '...but no more';

$PKG++;

# using tags broke subsequent imports in 0.01
import_ok   't::Tags',      '',             '->import still works';

$PKG++;

import_ok   't::Tags',      ':foo public',  'tag+more import';
is_import   qw/tag1 tag2 public t::Tags/,   '...imports correctly';

{
    package t::Consts;
    Exporter::NoWork->import(-CONSTS => 'default');

    sub default { 1; }
    sub CONSTANT { 1; }
    sub _PRIVATE { 1; }
}

BEGIN { $tests += 8 }

$PKG++;

import_ok   't::Consts',    '',             '-CONSTS blank import';
is_import   qw/default CONSTANT t::Consts/, '...imports constants';
cant_ok     qw/_PRIVATE/,                   '...public only';

$PKG++;

import_ok   't::Consts',    ':DEFAULT',     '-CONSTS :DEFAULT import';
is_import   qw/default CONSTANT t::Consts/, '...imports constants';

$PKG++;

import_ok   't::Consts',    ':CONSTS',      ':CONSTS import';
is_import   qw/CONSTANT/,   't::Consts',    '...imports constants';
cant_ok     'default',                      '...but not ordinary subs';

{
    package t::Magic;
    Exporter::NoWork->import(-MAGIC =>);

    sub MAGIC  { 1; }
}

BEGIN { $tests += 2 }

$PKG++;

import_nok  't::Magic',     'MAGIC',        '-MAGIC import fails';
like        $@, qr/Magic methods can't/,    '...with correct message';

my ($IMPORT, $defsv);

{
    package t::IMPORT;
    Exporter::NoWork->import;
    
    sub IMPORT { 
        $IMPORT++; 
        shift; 
        return map { (my $x = $_) =~ s/foo/bar/; $x } @_;
    }

    sub foo { 1; }
    sub bar { 1; }

    package t::ParentIMP;
    our @ISA = 't::IMPORT';

    sub afoo { 1; }
    sub abar { 1; }
}

BEGIN { $tests += 6 }

$PKG++;

import_ok   't::IMPORT', 'foo',     'package with IMPORT';
is          $IMPORT,    1,          '...which gets called';
is_import   'bar', 't::IMPORT',     '...and the return value honoured';

$PKG++;

import_ok   't::ParentIMP', 'afoo', 'package with inherited IMPORT';
is          $IMPORT,    2,          '...which gets called';
is_import   'abar', 't::ParentIMP', '...and the return value honoured';

my $CONFIG;

{
    package t::Config;
    Exporter::NoWork->import;

    our %CONFIG = (
        hash    => sub { $CONFIG = "hash $_[0]" },
        arg     => sub { $CONFIG = "hash $_[0] " . shift @{$_[2]} },
    );

    sub CONFIG {
        $CONFIG = "meth $_[0] $_[1]";
        $_[1] eq 'marg' and $CONFIG .= ' ' . shift @{$_[2]};
    }

    sub public { 1; }
    sub fake   { 1; }

    package t::Config::Inherit;
    our @ISA = 't::Config';
}

BEGIN { $tests += 12 }

$PKG++;

import_ok   't::Config',    '-hash',        'import with option';
is          $CONFIG,        'hash t::Config',    '...calls sub in %CONFIG';

$PKG++; $CONFIG = '';

import_ok   't::Config',    '-hash public', 'import w/option and sub';
is          $CONFIG,        'hash t::Config',    '...calls sub in %CONFIG';
is_import   'public',       't::Config',    '...and imports sub';

$PKG++; $CONFIG = '';

import_ok   't::Config',    '-arg fake',    'option w/arg';
is          $CONFIG,        'hash t::Config fake',
                                            '...calls sub in %CONFIG';
cant_ok     'fake',                         '...doesn\'t import';

$PKG++; $CONFIG = '';

import_ok   't::Config',    '-arg fake public',
                                            'option, arg, & sub';
is          $CONFIG,        'hash t::Config fake',
                                            '...calls sub in %CONFIG';
cant_ok     'fake',                         '...doesn\'t import arg';
is_import   'public',       't::Config',    '...does import sub';

BEGIN { $tests += 12 }

$PKG++; $CONFIG = '';

import_ok   't::Config',    '-bar',         'import with option';
is          $CONFIG,        'meth t::Config bar',
                                            '...calls ->CONFIG';

$PKG++; $CONFIG = '';

import_ok   't::Config',    '-bar public',  'import w/option and sub';
is          $CONFIG,        'meth t::Config bar',
                                            '...calls ->CONFIG';
is_import   'public',       't::Config',    '...and imports sub';

$PKG++; $CONFIG = '';

import_ok   't::Config',    '-marg fake',   'option w/arg';
is          $CONFIG,        'meth t::Config marg fake',
                                            '...calls ->CONFIG';
cant_ok     'fake',                         '...doesn\'t import';

$PKG++; $CONFIG = '';

import_ok   't::Config',    '-marg fake public',
                                            'option, arg, & sub';
is          $CONFIG,        'meth t::Config marg fake',
                                            '...calls ->CONFIG';
cant_ok     'fake',                         '...doesn\'t import arg';
is_import   'public',       't::Config',    '...does import sub';

BEGIN { $tests += 2 }

$PKG++; $CONFIG = '';

import_ok   't::Config::Inherit',   '-foo', 'inherited ->CONFIG';
is          $CONFIG, 'meth t::Config::Inherit foo',
                                            '...calls method';

BEGIN { plan tests => $tests }
