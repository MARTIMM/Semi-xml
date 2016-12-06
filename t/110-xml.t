use v6.c;
use Test;
use SemiXML;

#-------------------------------------------------------------------------------
# Testing http-header
# Options under 
#-------------------------------------------------------------------------------
# Setup
#
my $content = q:to/EOSX/;
$|html [
  $|body [
    $|h1 [burp]
    $|p [this is it!]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {
  option => {
    http-header => {
      show => 1,
      content-type => 'text/html',
      content-language => 'en'
    },

    doctype => {
      show => 1,                        # Default 0
    },

    xml-prelude => {
      show => 1,                        # Default 0
    }
  },
}

#-------------------------------------------------------------------------------
my SemiXML::Sxml $x .= new;
$x.parse( :$content, :$config);

my Str $xml-text = ~$x;
#say $xml-text;

ok $xml-text ~~ m:s/ 'content-type' ':' 'text/html' /, 'Http content type';
ok $xml-text ~~ m:s/ 'content-language' ':' 'en' /, 'Http content language';

#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
