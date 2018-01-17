use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML::Content;
use XML;

#-------------------------------------------------------------------------------
class Body {

  has Array $.content;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {
    $!content = [];
  }

  #-----------------------------------------------------------------------------
  method content ( SemiXML::Content:D $content ) {

    $!content.push($content);
  }

  #-----------------------------------------------------------------------------
  method xml ( XML::Node $parent, Bool :$keep = False ) {

    for @$!content -> $c {
      $c.xml( $parent, :$keep);
    }
  }
}
