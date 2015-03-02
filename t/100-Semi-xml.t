#!/usr/bin/env perl6
#
use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
#
my Semi-xml $x .= new;
isa_ok $x, 'Semi-xml', $x.^name;

my $html = 'xml-1';
role pink {
  has Hash $layout = { '$html' => 'xml' };
  has Hash $layout2 = { '$html' => 'xml' };
}

$x does pink;
isa_ok $x, 'Semi-xml', $x.^name;

say "M: \$x: ", $x.^methods;

my Str $sx-text = q:to/EOSX/;
$html [
  $head [
    $title [ Title of page ]
  ]
  $body [
    $h1 [ Introduction ]
    $p class=green [ Piece of text. See $a href=google.com [google]]
  ]
]
EOSX

$x.parse(content => $sx-text);










my Str $sx-text1 = q:to/EOSX/;
$html [
  $head [
    $title [ Title of page ]
  ]
  $body [
    $h1 [ Introduction ]
    $p class=green [ Piece of text. See $a href=google.com [google]]
  ]
]
EOSX







#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
