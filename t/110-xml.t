use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing http-header
# Options under
#-------------------------------------------------------------------------------
# Setup
my $content = q:to/EOSX/;
$html [
  $body [
    $h1 [burp]
    $p [this is it!]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {
  C => {
    out-fmt => {
      header-show =>  True,
      doctype-show => True,
      xml-show => True
    }
  },

  H => {
    out-fmt => {
      content-type => 'text/html',
      content-language => 'en'
    }
  }
};

#-------------------------------------------------------------------------------
my SemiXML::Sxml $x .= new( :!trace, :merge, :refine([<in-fmt out-fmt>]));
$x.parse( :$content, :$config);
my Str $xml-text = ~$x;
#note $xml-text;

like $xml-text, /:s 'content-type' ':' 'text/html' /, 'Http content type';
like $xml-text, /:s 'content-language' ':' 'en' /, 'Http content language';

#-------------------------------------------------------------------------------
# Cleanup
done-testing();
exit(0);
