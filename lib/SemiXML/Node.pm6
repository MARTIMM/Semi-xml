use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
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
  has Bool $.inline is rw;      # inline in FTable
  has Bool $.noconv is rw;      # no-conversion in FTable
  has Bool $.keep is rw;        # space-preserve in FTable
  has Bool $.close is rw;       # self-closing in FTable

  #-----------------------------------------------------------------------------
  multi method parent ( SemiXML::Node:D $!parent ) { }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method parent ( Bool:D :$undef!) { $!parent = SemiXML::Node if $undef; }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method parent ( --> SemiXML::Node ) { $!parent }

  #-----------------------------------------------------------------------------
  method undef-nodes ( ) { $!nodes = [] }

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

    $!parent.removeChild(self) if $!parent;
    return self
  }

  #-----------------------------------------------------------------------------
  method reparent ( SemiXML::Node $parent --> SemiXML::Node ) {

#note "Repar 0: $parent.name(), $!name";
#note "Repar 1: $!parent";
    #self.remove;
    $!parent.removeChild(self);

    $!parent = $parent;
    return self
  }

  #-----------------------------------------------------------------------------
  method removeChild ( SemiXML::Node $node ) {

    my $pos = self.index-of($node);
#note "rmChild: $!name, $node.name(), pos = {$pos//'-'}";
    $!nodes.splice( $pos, 1) if $pos.defined;
  }

  #-----------------------------------------------------------------------------
#TODO move into separate module and use with 'handles'
  # append a node to the end of the nodes array if the node is not
  # already in that array.
  multi method append ( SemiXML::Node:D $node! ) {

    # if node has a parent, remove the node from the parent first
    $node.remove;

    # add the node when not found and set the parent in the node
    my $pos = self.index-of($node);
    unless $pos.defined {
      $!nodes.push($node);
      $node.parent(self);
    }
  }

  #-----------------------------------------------------------------------------
  # insert a node to the start of the nodes array if the node is not
  # already in that array.
  method insert ( SemiXML::Node:D $node ) {

    $node.remove;

    my $pos = self.index-of($node);
    unless $pos.defined {
      $!nodes.unshift($node);
      $node.parent(self);
    }
  }

  #-----------------------------------------------------------------------------
  multi method before ( SemiXML::Node $node, SemiXML::Node $new, :$offset=0 ) {
#note "Before: $!name, $node.name(), $new.name()";

    my Int $pos = self.index-of($node);
    $!nodes.splice( $pos + $offset, 0, $new.reparent(self))
      if $pos.defined and $pos >= 0 and ($pos + $offset) < $!nodes.elems;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method before ( SemiXML::Node $node ) {

    if $!parent.defined {
      $node.parent(self) unless $node.parent;
      $!parent.before( self, $node);
    }
  }

  #-----------------------------------------------------------------------------
  multi method after ( SemiXML::Node $node, SemiXML::Node $new, :$offset=1 ) {

    self.before( $node, $new, :$offset);
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method after ( SemiXML::Node $node ) {

    if $!parent.defined {
      $!parent.after( self, $node);
    }
  }

  #-----------------------------------------------------------------------------
  method previousSibling ( --> SemiXML::Node ) {

    if $!parent.defined {
      my $pos = $!parent.index-of(self);
      return $!parent.nodes[$pos-1] if $pos > 0;
    }

    return SemiXML::Node;
  }

  #-----------------------------------------------------------------------------
  method nextSibling ( --> SemiXML::Node ) {

    if $!parent.defined {
      my $pos = $.parent.index-of(self);
      return $.parent.nodes[$pos+1] if $pos < $.parent.nodes.end;
    }

    return SemiXML::Node;
  }

  #-----------------------------------------------------------------------------
  # copy a few html global attributes; class, data-*, id, style and title.
  method cp-std-attrs ( Hash $attributes ) {

    return unless ?$attributes;

    for $attributes.keys {
      when /^ [ class || data\- \S+ || id || style || title ] $/ {
        $!attributes{$_} = ~$attributes{$_};
      }
    }
  }

  #-----------------------------------------------------------------------------
  # return current attributes
  multi method attributes ( --> Hash ) is rw {
    $!attributes
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # set attributes
  multi method attributes ( Hash:D $!attributes ) {

    self!process-attributes;
  }

  #----[ private stuff ]--------------------------------------------------------
  # process the text processing control parameters and set sxml attributes
  # of the node. This is done for elements as well as text nodes.
  method !process-attributes ( ) {

#note "PA 0: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
    # a normal element(Plain) might have entries in the FTable configuration.
    # when entries aren't found, results are False.
    my Hash $ftable = $!globals.refined-tables<F> // {};
    $!inline = $!name ~~ any(|@($ftable<inline> // []));
    $!noconv = $!name ~~ any(|@($ftable<no-conversion> // []));
    $!keep = $!name ~~ any(|@($ftable<space-preserve> // []));
    $!close = $!name ~~ any(|@($ftable<self-closing> // []));

#note "PA 1: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
    # then inherit the data from the parent. root doesn't have a parent as well
    # as method generated nodes
    if ?$!parent {
      $!inline = ($!parent.inline or $!inline);
      $!noconv = ($!parent.noconv or $!noconv);
      $!keep = ($!parent.keep or $!keep);
      $!close = ($!parent.close or $!close);
    }

#note "PA 2: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
    # keep can be overruled by a global keep when True
    $!keep or= $!globals.keep;

#note "PA 3: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
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
#note "PA 4: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
  }
}
