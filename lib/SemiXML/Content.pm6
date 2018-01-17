use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML::Text;
use XML;

#-------------------------------------------------------------------------------
class Content {

  has Array $.parts;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {
    $!parts = [];
  }

  #-----------------------------------------------------------------------------
  method part ( Any:D $part ) {

    if $part.^name ~~ any(<SemiXML::Element SemiXML::Text>) {

      $!parts.push($part);
    }

    else {

      die 'Only parts of type Text or Element can be added';
    }
  }

  #-----------------------------------------------------------------------------
  method xml ( XML::Element $parent, Bool :$keep = False --> XML::Node ) {

    for @$!parts -> $p { 
      if $p.^name ~~ SemiXML::Element {
        $parent.append($p.xml);
      }

      elsif $p.^name ~~ SemiXML::Text {
        # :keep comes from owners element
        $parent.append($p.xml(:$keep));
      }
    }


    $parent
  }
}
