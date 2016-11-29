use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Code {

  has Array $!parts = [ ];
  has Int $!count = 0;

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
  
#say "C: $parent";
#say "B: ", ~$content-body;

    $!parts.push: { code => $content-body, };

    my XML::Element $c = append-element( $parent, 'code');
    append-element( $c, :text($!count.Str));

#say $!parts.elems;
    $!count++;
    $parent;
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method get-code-part ( Int $entry --> XML::Element ) {

    $!parts[$entry]<code>;
  }
}
