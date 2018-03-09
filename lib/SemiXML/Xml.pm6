use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
#use SemiXML::Node;
#use SemiXML::Element;
#use SemiXML::Text;
use XML;
#use XML::XPath;

#-------------------------------------------------------------------------------
class Xml {

  #-----------------------------------------------------------------------------
  sub append-element (
    XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
    --> XML::Node
  ) is export {

    # create a text element, even when it is an empty string.
    my XML::Node $text-element = SemiXML::XMLText.new(:$text) if $text.defined;

    # create an element only when the name is defined and not empty
    my XML::Node $element =
       XML::Element.new( :$name, :attribs(%$attributes)) if ? $name;

    # if both are created than add text to the element
    if ? $element and ? $text-element {
      $element.append($text-element);
    }

    # if only text, then the element becomes the text element
    elsif ? $text-element {
      $element = $text-element;
    }

    # else $name -> no change to $element. No name and no text is an error.
#    die "No element nor text defined" unless ? $element;

    $parent.append($element);
    $element;
  }

  #-----------------------------------------------------------------------------
  sub insert-element (
    XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
    --> XML::Node
  ) is export {

    my XML::Node $text-element = SemiXML::XMLText.new(:$text) if $text.defined;
    my XML::Node $element =
       XML::Element.new( :$name, :attribs(%$attributes)) if ? $name;

    if ? $element and ? $text-element {
      $element = SemiXML::XMLText.new(:$text);
    }

    elsif ? $text-element {
      $element = $text-element;
    }

    $parent.insert($element);
    $element;
  }

  #-----------------------------------------------------------------------------
  sub before-element (
    XML::Element $node, Str $name = '', Hash $attributes = {}, Str :$text = ''
    --> XML::Node
  ) is export {

    my XML::Node $element;

    if ? $text {
      $element = SemiXML::XMLText.new(:$text);
    }

    else {
      $element = XML::Element.new( :$name, :attribs(%$attributes));
    }

    $node.before($element);
    $element;
  }

  #-----------------------------------------------------------------------------
  sub after-element (
    XML::Element $node, Str $name = '', Hash $attributes = {}, Str :$text = ''
    --> XML::Node
  ) is export {

    my XML::Node $element;

    if ? $text {
      $element = SemiXML::XMLText.new(:$text);
    }

    else {
      $element = XML::Element.new( :$name, :attribs(%$attributes));
    }

    $node.after($element);
    $element;
  }
}
