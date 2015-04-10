use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Role add to parser class
#   Translation of smi-xml text
#   Control of output via role
#   Result to text
#   test attributes
#-------------------------------------------------------------------------------
# Setup
#
my Semi-xml $x .= new;
isa_ok $x, 'Semi-xml', $x.^name;

# Def=vise a role to add
#
role pink {
  has Hash $!configuration = {
             option => {
               doctype => {
#                 definition => '',
#                 entities => []
                 show => 1,
               },
               xml-prelude => {
                 show => 1,
                 version => '1.0',
                 encoding => 'UTF-8'
               },
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
    $h1 class=green id=h1001 [ Introduction ]
    $p class=green [ Piece of \[text\]. See $a href=google.com [google]]
    $x class='green blue' [ empty but not ]
    $y data_1='quoted"test"' [ empty but not ]
    $z data_2="double 'quoted' tests" [ empty but not ]
    $br[]
  ]
]
EOSX

# And parse it
#
$x.parse(content => $sx-text);

# See the result
#
my Str $xml-text = ~$x;
ok $xml-text ~~ ms/'<?xml' 'version="1.0"' 'encoding="UTF-8"?>'/,
   'Xml prelude found';
ok $xml-text ~~ ms/\<\!DOCTYPE html\>/, 'Doctype found';
ok $xml-text ~~ m/\<html\>/, 'Top level html found';
ok $xml-text ~~ m/\<head\>/, 'Head found';
ok $xml-text ~~ m/\<body\>/, 'Body found';
ok $xml-text ~~ m/\<br\/\>/, 'Empty tag br found';

ok $xml-text ~~ m/'<p class="green">'/, 'Class test 1';
ok $xml-text ~~ m/'<x class="green blue">'/, 'Class test 2';
ok $xml-text ~~ m/'<y data_1="quoted&quot;test&quot;">'/, 'Class test 3';
ok $xml-text ~~ m/'<z data_2="double \'quoted\' tests">'/, 'Class test 4';


#say $xml-text;



#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
