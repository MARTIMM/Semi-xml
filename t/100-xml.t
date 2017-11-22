use v6;

use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Translation of SemiXML text
#   Result to text
#   test attributes
#-------------------------------------------------------------------------------
# Setup
my SemiXML::Sxml $x .= new( :merge, :refine([<in-fmt out-fmt>]));
isa-ok $x, 'SemiXML::Sxml', $x.^name;

# Setup the text to parse
my Str $sx-text = q:to/EOSX/;
$html [
  $head [
    $title [ Title of page is used here ]
  ]
  $body [
    $h1 class=green id=h1001 [ Introduction ]
    $p class=green [ Piece of \[text\]. See $a href=google.com [ google ] ]
    $x class='green blue' [ empty but not ]
    $y data_1='quoted"test"' [ empty but not ]
    $z data_2="double 'quoted' attrs" [ empty but not ]
    $eq1 empty-single=''
    $eq2 empty-double=""
    $br
  ]
]
EOSX

# And parse it
$x.parse(
  content => $sx-text,
  config => {
    C => {
      out-fmt => {
        xml-show => True,
        doctype-show => True
      }
    },

    F => {
      in-fmt => {
        self-closing => ['br'],
      }
    },
  }
);

# See the result
my Str $xml-text = ~$x;
#note $xml-text;

like $xml-text, /:s '<?xml' 'version="1.0"' 'encoding="UTF-8"?>'/,
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

like $xml-text, / :s eq1 empty\-single\=\"\" /, "single quotes";
like $xml-text, / :s eq2 empty\-double\=\"\" /, "double quotes";

#-------------------------------------------------------------------------------
# Cleanup
done-testing;
