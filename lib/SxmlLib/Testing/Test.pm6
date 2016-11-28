use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

my Array $xml-parts = [ ];
my Array $code-parts = [ ];

#-------------------------------------------------------------------------------
class Test {

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
  
say "T: ", ~$parent;
say "B: ", ~$content-body;

    $parent;
  }
}
