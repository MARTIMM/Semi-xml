use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing SxmlLib::Docbook5::Basic;
# Check of basic docbook methods using Db5-b as modulename ...
# module/Db5-b:                   SxmlLib::Docbook5::Basic;
#
#     $.Db5-b.book              Modify book tag to get needed attributes
#     $.Db5-b.article           Same as book for article tag.
#
#     $!Db5-b.info              Info tag.
#-------------------------------------------------------------------------------
# Setup
#
my $sxml-text = q:to/EOSX/;
---
options/xml-prelude/show:       1;
options/doctype/show:           1;

module/Db5-b:                   SxmlLib::Docbook5::Basic;
---
$.Db5-b.article [
  $title [ Using Docbook 5 ]
  $!Db5-b.info firstname=Marcel surname=Timmerman email=mt1957@gmail.com
               city=Haarlem country=Netherlands [
    $para [abstract test]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Semi-xml $x .= new;
$x.parse(:content($sxml-text));

my Str $xml-text = ~$x;
say $xml-text;

ok $xml-text ~~ m/' '/, 'Check comments';

#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
