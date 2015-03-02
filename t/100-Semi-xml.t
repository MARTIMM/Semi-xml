#!/usr/bin/env perl6
#
use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
#
my Semi-xml $x .= new;
isa_ok $x, 'Semi-xml', $x.^name;

role pink {
  our $html = 'xml';
}

$x does pink;
isa_ok $x, 'Semi-xml', $x.^name;


my Str $sx-text = q:to/EOSX/;
$html [
]
EOSX

$x.parse(content => $sx-text);
















#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
