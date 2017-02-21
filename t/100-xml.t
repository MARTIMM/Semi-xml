use v6.c;

use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Role add to parser class
#   Translation of SemiXML text
#   Control of output via role
#   Result to text
#   test attributes
#-------------------------------------------------------------------------------
# Setup
my SemiXML::Sxml $x .= new(:trace);
isa-ok $x, 'SemiXML::Sxml', $x.^name;

# Setup the text to parse
my Str $sx-text = q:to/EOSX/;
$|html [
  $|head [
    $|title [ Title of page $ is used here ]
  ]
  $|body [
    $|h1 class=green id=h1001 [ Introduction ]
    $|p class=green [ Piece of \[text\]. See $|a href=google.com [google]]
    $|x class='green blue' [ empty but not ]
    $|y data_1='quoted"test"' [ empty but not ]
    $|z data_2="double 'quoted' attrs" [ empty but not ]
    $|br []
  ]
]
EOSX

# And parse it
$x.parse(
  content => $sx-text,
  config => {
    option => {
      doctype => {
        show => 1,
      },
      xml-prelude => {
        show => 1,
        version => '1.0',
        encoding => 'UTF-8'
      },
    }
  }
);

# See the result
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
like $xml-text,
     /'<y data_1="quoted&quot;test&quot;">'/,
     'Class test 3';
like $xml-text,
     / :s '<z data_2="double' "'quoted'" 'attrs">'/,
     'Class test 4';


#say $xml-text;



#-------------------------------------------------------------------------------
# Cleanup
done-testing();
exit(0);
