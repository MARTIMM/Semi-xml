use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Node;
use SemiXML::Element;
use SemiXML::Text;

#-------------------------------------------------------------------------------
class SxmlHelper {

  #-----------------------------------------------------------------------------
  sub append-element (
    SemiXML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
#    --> XML::Node
  ) is export {

    # create a text element, even when it is an empty string.
    my SemiXML::Node $text-element = SemiXML::Text.new(:$text) if $text.defined;

    # create an element only when the name is defined and not empty
    my SemiXML::Node $element =
       SemiXML::Element.new( :$name, :%$attributes) if ? $name;

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
#    $element;
  }


}
