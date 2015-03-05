use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Role add to parser class
#   Translation of smi-xml text
#   Control of output via role
#   Result to text
#-------------------------------------------------------------------------------
# Setup
#
my Semi-xml $x .= new;
isa_ok $x, 'Semi-xml', $x.^name;

# Def=vise a role to add
#
my $html = 'xml-1';
role pink {
  has Hash $!configuration = {
             options => {
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
ok $xml-text ~~ ms/\<\?xml version\=\"1\.0\" encoding\=\"UTF\-8\"\?\>/;
ok $xml-text ~~ ms/\<\!DOCTYPE html\>/;
ok $xml-text ~~ m/\<html\>/, 'Top level html found';
ok $xml-text ~~ m/\<head\>/, 'Head found';
ok $xml-text ~~ m/\<body\>/, 'Body found';
ok $xml-text ~~ m/\<br\/\>/, 'Empty tag br found';


#say $xml-text;



#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
