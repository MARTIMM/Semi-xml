#!/usr/bin/env perl6
#
use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Setup
#
my Semi-xml $x .= new;
isa_ok $x, 'Semi-xml', $x.^name;

# Def=vise a role to add
#
my $html = 'xml-1';
role pink {
  has Hash $!styles = { '.green' => { color => '#00aa0f' }};
  has Hash $!configuration = { doctype =>
                               { doc-element => 'html',
                                 system-location => '',
                                 public-location => '', # one of the locations
                                 internal-subset => []
                               }
                             };
}

# Add the role to the parser
#
$x does pink;
is $x.^name, 'Semi-xml+{pink}', $x.^name;

# Setup the text to parse
#
my Str $sx-text = q:to/EOSX/;
$html [
  $head [
    $title [ Title of page \$ is used here ]
  ]
  $body [
    $h1 [ Introduction ]
    $p class=green [ Piece of \[text\]. See $a href=google.com [google]]
    $br[]
  ]
]
EOSX

# And parse it
#
$x.parse(content => $sx-text);

# See the result
#
my $xml-text = $x.Str;
ok $xml-text ~~ /\<html\>/, 'Top level html found';
ok $xml-text ~~ /\<head\>/, 'Head found';
ok $xml-text ~~ /\<body\>/, 'Body found';
ok $xml-text ~~ /\<br\/\>/, 'Empty tag br found';


say $xml-text;



#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
