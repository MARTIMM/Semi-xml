use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
#use SemiXML::StringList;
#use SemiXML::Body;
#use XML;

#-------------------------------------------------------------------------------
role Node {

  has SemiXML::Globals $.globals;

  # references its parent or Nil if on top. when finished it points to
  # the document element at the root
  has SemiXML::Node $.parent;

  # all nodes contained in the bodies.
  has Array $.nodes;

  # body count kept in the node. the body number is the content body where
  # the node was found.
  has Int $.body-count is rw = 0;
  has Int $.body-number is rw = 0;
  has SemiXML::BodyType $.body-type is rw;

  # this nodes type
  has SemiXML::NodeType $.node-type is rw;

  # flags to process the content. element nodes set them and text nodes
  # inherit them. other types like PI, CData etc, do not need it.
  has Bool $.inline = False;  # inline in FTable
  has Bool $.noconv = False;   # no-conversion in FTable
  has Bool $.keep = False;    # space-preserve in FTable
  has Bool $.close = False;   # self-closing in FTable

  #-----------------------------------------------------------------------------
  method parent ( SemiXML::Node:D $!parent ) { }

  #-----------------------------------------------------------------------------
  # find location of node in nodes array. return Int type if not found.
  method index-of ( SemiXML::Node $find --> Int ) {

    loop ( my Int $i = 0; $i < $!nodes.elems; $i++ ) {
      return $i if $!nodes[$i] ~~ $find;
    }

    Int
  }

  #-----------------------------------------------------------------------------
  method remove ( --> SemiXML::Node ) {

    $!parent.removeChild(self);
    return self
  }

  #-----------------------------------------------------------------------------
  method reparent ( SemiXML::Node $parent --> SemiXML::Node ) {

    #self.remove;
    $!parent.removeChild(self);
    $!parent = $parent;
    return self
  }

  #-----------------------------------------------------------------------------
  method removeChild ( SemiXML::Node $node ) {

    my $pos = self.index-of($node);
    $!nodes.splice( $pos, 1) if ?$pos;
  }
}
