use v6.c;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing SxmlLib::Docbook5::Basic;
# Check of basic docbook methods using Db5 as modulename ...
# 'module/Db5: SxmlLib::Docbook5::Basic;'
#
#     $.Db5.book                Modify book tag to get needed attributes
#     $.Db5.article             Same as book for article tag.
#
#     $!Db5.info                Info tag.
#-------------------------------------------------------------------------------
# Setup
#
my $sxml-text = q:to/EOSX/;
---
option/xml-prelude/show:       1;
option/doctype/show:           1;

module/Db5:                   SxmlLib::Docbook5::Basic;
---
$.Db5.article [
  $title [ Using Docbook 5 ]
  $!Db5.info firstname=Marcel surname=Timmerman email=mt1957@gmail.com
             city=Haarlem country=Netherlands
             copy-year='2015, 2016 ... Inf' copy-holder='Marcel Timmerman' [
    $para [abstract test]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Semi-xml::Sxml $x .= new;
$x.parse(:content($sxml-text));

my Str $xml-text = ~$x;
#say $xml-text;

ok $xml-text ~~ m/'<info>'/, 'Check info';
ok $xml-text ~~ m/'<author><personname>' .*? '<firstname>Marcel'/, 'Check firstname';
ok $xml-text ~~ m/'<author><personname>' .*? '<surname>Timmerman'/, 'Check surname';
ok $xml-text ~~ m/'<address>' .*? '<city>Haarlem'/, 'Check city';
ok $xml-text ~~ m/'<address>' .*? '<country>Netherlands'/, 'Check country';
ok $xml-text ~~ m/'<copyright>' .*? '<year>2015, 2016 ... Inf'/, 'Check copyright year';
ok $xml-text ~~ m/'<copyright>' .*? '<holder>Marcel Timmerman'/, 'Check copyright holder';
ok $xml-text ~~ m/'<date>' \d**4 (\-\d\d)**2 '</date>'/, 'Check date';
ok $xml-text ~~ m/'<abstract><para>abstract test</para></abstract>'/, 'Check abstract';

#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
