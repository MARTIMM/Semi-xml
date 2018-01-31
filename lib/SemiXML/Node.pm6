use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
#use SemiXML::StringList;
#use SemiXML::Body;
use XML;

#-------------------------------------------------------------------------------
role Node {

  has SemiXML::Globals $.globals;

  has Str $.name;
  has Str $.namespace;

  has Str $!module;
  has Str $!method;

  has Hash $.attributes;

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
  has Bool $.noconv = False;  # no-conversion in FTable
  has Bool $.keep = False;    # space-preserve in FTable
  has Bool $.close = False;   # self-closing in FTable

  #-----------------------------------------------------------------------------
  multi method parent ( SemiXML::Node:D $!parent ) { }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method parent ( --> SemiXML::Node ) { $!parent }

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
note "rmChild: $!name, $node.name(), pos = {$pos//'-'}";
    $!nodes.splice( $pos, 1) if ?$pos;
  }

  #-----------------------------------------------------------------------------
  # return current attributes
  multi method attributes ( --> Hash ) is rw {
    $!attributes
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # set attributes
  multi method attributes ( Hash:D $attributes ) {
    my Hash $a = $!attributes;
    my Hash $b = hash( |$a, |$attributes );
    $!attributes = $b;
    self!process-attributes;
  }

  #----[ private stuff ]--------------------------------------------------------
  # process the text processing control parameters and set sxml attributes
  # of the node. This is done for elements as well as text nodes.
  method !process-attributes ( ) {

    # a normal element(Plain) might have entries in the FTable configuration.
    # when entries aren't found, results are False.
    my Hash $ftable = $!globals.refined-tables<F> // {};
    $!inline = $!name ~~ any(|@($ftable<inline> // []));
    $!noconv = $!name ~~ any(|@($ftable<no-conversion> // []));
    $!keep = $!name ~~ any(|@($ftable<space-preserve> // []));
    $!close = $!name ~~ any(|@($ftable<self-closing> // []));

    # then inherit the data from the parent. root doesn't have a parent as well
    # as method generated nodes
    if ?$!parent {
      $!inline = ($!parent.inline or $!inline);
      $!noconv = ($!parent.noconv or $!noconv);
      $!keep = ($!parent.keep or $!keep);
      $!close = ($!parent.close or $!close);
    }

    # keep can be overruled by a global keep
    $!keep = $!globals.keep;

    # then the sxml attributes on the node overrule all
    for $!attributes.keys -> $key {
      given $key {
        when /^ sxml ':' inline / {
          $!inline = $!attributes{$key}.Int.Bool;
        }

        when /^ sxml ':' noconv / {
          $!noconv = $!attributes{$key}.Int.Bool;
        }

        when /^ sxml ':' keep / {
          $!keep = $!attributes{$key}.Int.Bool;
        }

        when /^ sxml ':' close / {
          $!close = $!attributes{$key}.Int.Bool;
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  # set sxml attributes from values in self or $node when provided
  method !set-attributes ( SemiXML::Node $node? ) {

    my SemiXML::Node $n = $node // self;
    $n.attributes<sxml:inline> = $n.inline ?? 1 !! 0;
    $n.attributes<sxml:noconv> = $n.noconv ?? 1 !! 0;
    $n.attributes<sxml:keep> = $n.keep ?? 1 !! 0;
    $n.attributes<sxml:close> = $n.close ?? 1 !! 0;
  }
}
