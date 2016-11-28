use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

my Array $xml-parts = [ ];
my Array $code-parts = [ ];

#-------------------------------------------------------------------------------
class Report {

  has $!test-obj;
  has $!code-obj;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $sxml, Hash $attrs ) {

say "\nInit report: ";
for $attrs.kv -> $k, $v { say "$k => $v" };
print "\n";

    $!code-obj = $sxml.get-sxml-object('SxmlLib::Testing::Code');
    $!test-obj = $sxml.get-sxml-object('SxmlLib::Testing::Test');
  }

  #-----------------------------------------------------------------------------
  method overview (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

say "R: $parent";
say "B: ", ~$content-body;
    $parent;
  }

  #-----------------------------------------------------------------------------
  method summary (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    $parent;
  }
}
