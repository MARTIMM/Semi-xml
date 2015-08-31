use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing http-header
# Options under 
#-------------------------------------------------------------------------------
# Setup
#
my $sxml-text = q:to/EOSX/;
---
option/http-header/show:                1;
option/http-header/content-type:        text/html;
option/http-header/content-language:    en;

option/xml-prelude/show:                1;

option/doctype/show:                    1;
---
$html [
  $body [
    $h1 [burp]
    $p [this is it!]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Semi-xml::Sxml $x .= new;
$x.parse(:content($sxml-text));

my Str $xml-text = ~$x;
#say $xml-text;

ok $xml-text ~~ m:s/ 'content-type' ':' 'text/html' /, 'Http content type';
ok $xml-text ~~ m:s/ 'content-language' ':' 'en' /, 'Http content language';

#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
