use v6.c;
use SemiXML;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Code {

  has Array $!parts = [ ];
  has Int $!count = 0;

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
  
    $!parts.push: { code => $content-body, };

    my XML::Element $c = append-element( $parent, 'code');
    append-element( $c, :text($!count.Str));

    $!count++;
    $parent;
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method get-code-part ( Int $entry --> XML::Element ) {

    $!parts[$entry]<code>;
  }
}
