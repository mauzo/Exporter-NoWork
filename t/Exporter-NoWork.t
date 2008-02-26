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

    my $eval = eval "package $PKG; $mod->import(qw/$args/); 1";

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
        defined &$to or push @nok, <<DIAG;
  \&$to is not defined
DIAG
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
}

BEGIN { $tests += 3 }

can_ok  't::Basic',     'import';
ok(     t::Basic->isa('Exporter::NoWork'),  'inheritance is set up');

# [rt.cpan.org #33595]
is grep($_ eq 'Exporter::NoWork', @t::Basic::ISA), 1, '...but only once';

BEGIN { $tests += 8 }

my @subs = qw/public _private CAPS import ALL/;

import_ok   't::Basic', '',             'empty import list';
cant_ok     @subs,                      '...imports nothing';

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

BEGIN { $tests += 9 }

$PKG++;

import_ok   't::Default',   '',             'blank import';
is_import   'default',      't::Default',   '...imports default';
cant_ok     qw/public _private/,            '...but no more';

$PKG++;

import_ok   't::Default',   ':DEFAULT',     ':DEFAULT import';
is_import   'default',      't::Default',   '...imports default';
cant_ok     qw/public _private/,            '...but no more';

$PKG++;

import_ok   't::Default',   ':DEFAULT public',
                                            ':DEFAULT+more import';
is_import   qw/public default t::Default/,  '...imports correctly';
cant_ok     qw/_private/,                   '...but no more';

BEGIN { plan tests => $tests }
