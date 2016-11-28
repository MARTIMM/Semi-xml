use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

my Array $xml-parts = [ ];
my Array $code-parts = [ ];

#-------------------------------------------------------------------------------
class Code {

  has $!test-obj;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $sxml, Hash $attrs ) {

say "\nInit code: ";
for $attrs.kv -> $k, $v { say "$k => $v" };
print "\n";

    $!test-obj = $sxml.get-sxml-object('SxmlLib::Testing::Test');
  }

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
  
say "C: $parent";
say "B: ", ~$content-body;
    $parent;
  }
}
