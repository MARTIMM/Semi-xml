use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<github:MARTIMM>;

use XML;
use SemiXML::Sxml;
use SxmlLib::SxmlHelper;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
class Test {

  has $!sxml;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $!sxml, Hash $attrs ) {

  }

  #-----------------------------------------------------------------------------
  method run (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
note "Run: ", ~$content-body;
    my XML::Element $html = append-element( $parent, 'html');
    my XML::Element $head = self!head($html);
    my XML::Element $body = self!body($html);
    $body.append($content-body);
    $parent
  }

  #-----------------------------------------------------------------------------
  method code (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    $parent.append($content-body);
    $parent
  }

  #-----------------------------------------------------------------------------
  method !head ( XML::Element $html --> XML::Element ) {
    append-element( $html, 'head');
  }

  #-----------------------------------------------------------------------------
  method !body ( XML::Element $html --> XML::Element ) {
    append-element( $html, 'body');
  }
}
