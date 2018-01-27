use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::StringList;
use SemiXML::Node;
use SemiXML::Text;
use XML;

#-------------------------------------------------------------------------------
class Element does SemiXML::Node {

  has Str $.name;
  has Str $.namespace;

  has Str $!module;
  has Str $!method;
#  has XML::Element $!content-body;

  has Hash $.attributes;

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( Str:D :$!name!, Hash :$!attributes = {} ) {

    given $!name {
      when 'sxml:cdata'   { $!node-type = SemiXML::CData; }
      when 'sxml:pi'      { $!node-type = SemiXML::PI; }
      when 'sxml:comment' { $!node-type = SemiXML::Comment; }
      default             { $!node-type = SemiXML::Plain; }
    }

    $!globals .= instance;
    $!nodes = [];

    # a normal element(Plain) might have entries in the FTable configuration
    self!process-FTable;

    # it can be overidden by attributes
    self!process-attributes;

    # keep can be overruled by a global keep
    $!keep = $!globals.keep;

    # set sxml attributes. these are removed later
    #self!set-attributes;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD (
    Str:D :$!module!, Str:D :$!method!, Hash :$!attributes = {}
  ) {
    $!node-type = SemiXML::Method;
    $!globals .= instance;
    $!nodes = [];

    # devise a temporary name for the node
    $!name = "sxml:$!module.$!method";

    self!process-attributes;

    # keep can be overruled by a global keep
    $!keep = $!globals.keep;

    # set sxml attributes. these are removed later
    #self!set-attributes;
  }

#`{{
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # can only be called from other code and cannot be used directly from
  # sxml text
  multi submethod BUILD ( Bool:D :$cdata! ) {
    $!node-type = SemiXML::CData;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD ( Bool:D :$pi! ) {
    $!node-type = SemiXML::PI;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD ( Bool:D :$comment! ) {
    $!node-type = SemiXML::Comment;
  }
}}

  #-----------------------------------------------------------------------------
  # append a node to the end of the nodes array if the node is not
  # already in that array.
  method append ( SemiXML::Node:D $node ) {

    # add the node when not found and set the parent in the node
    if self!not-in-nodes($node) {
      $!nodes.push($node);
      $node.parent(self);
    }
  }

  #-----------------------------------------------------------------------------
  # insert a node to the start of the nodes array if the node is not
  # already in that array.
  method insert ( SemiXML::Node:D $node ) {

    # add the node when not found and set the parent in the node
    if self!not-in-nodes($node) {
      $!nodes.unshift($node);
      $node.parent(self);
    }
  }

  #-----------------------------------------------------------------------------
  # search for the node in nodes array.
  method !not-in-nodes ( SemiXML::Node:D $node --> Bool ) {

    my Bool $not-in-nodes = True;
    for @($!nodes) -> $n {
      if $n === self {
        $not-in-nodes = False;
        last;
      }
    }

    $not-in-nodes
  }

  #-----------------------------------------------------------------------------
  method attributes ( Hash $!attributes ) {
    self!process-attributes;
  }

  #-----------------------------------------------------------------------------
  method xml (
    XML::Node $parent, Bool :$inline is copy = False,
    Bool :$noconv is copy = False, Bool :$keep is copy = False,
    Bool :$close is copy = False
  ) {
    given $!node-type {
      when any( SemiXML::Fragment, SemiXML::Plain) {
        self!plain-xml( $parent, :$inline, :$noconv, :$keep, :$close);
      }

      when SemiXML::CData {
        self!cdata-xml($parent);
      }

      when SemiXML::PI {
        self!pi-xml($parent);
      }

      when SemiXML::Comment {
        self!comment-xml($parent);
      }
    }
#`{{
    given $!node-type {
      when any( SemiXML::Fragment, SemiXML::Plain) {

note "$!node-type, $!body-number, $!name";
        my XML::Element $this-node-xml .= new(:$!name);
        for $!attributes.kv -> $k, $v {
          $this-node-xml.set( $k, ~$v);
        }

        $parent.append($this-node-xml);

        unless $!close {
          if $!nodes.elems {
            for @$!nodes -> $node {
              if $node.node-type !~~ SemiXML::Text {
                # inherit from parent nodes
                $inline = ($inline or $!inline);
                $noconv = ($noconv or $!noconv);
                $keep = ($keep or $!keep);
                $close = ($close or $!close);
              }

              $node.xml( $this-node-xml, :$inline, :$noconv, :$keep, :$close);
            }
          }

          else {
            $this-node-xml.append(SemiXML::XMLText.new(:text('')));
          }
        }
      }

      when SemiXML::Method {
note "$!node-type, $!body-number, $!module, $!method";
        $!content-body .= new(:$!name);
        for $!attributes.kv -> $k, $v {
          $!content-body.set( $k, ~$v);
        }

        $parent.append($!content-body);

        unless $!close {
          if $!nodes.elems {
            for @$!nodes -> $node {
              if $node.node-type !~~ SemiXML::Text {
                # inherit from parent nodes
                $inline = ($inline or $!inline);
                $noconv = ($noconv or $!noconv);
                $keep = ($keep or $!keep);
                $close = ($close or $!close);
              }

              $node.xml( $!content-body, :$inline, :$noconv, :$keep, :$close);
            }
          }

          else {
            $!content-body.append(SemiXML::XMLText.new(:text('')));
          }
        }
      }

      when SemiXML::CData {

      }

      when SemiXML::PI {

      }

      when SemiXML::Comment {
#        $parent.append(XML::Comment.new(:data($content-body.nodes)));
      }
    }
}}
  }

  #-----------------------------------------------------------------------------
  method run-method ( ) {
#`{{
    # first go to inner elements
    for @$!nodes -> $node {
      $node.run-method unless $node ~~ SemiXML::Text;
    }

    # then check if node is a method node
    if $!node-type ~~ SemiXML::Method {
note ">> $!node-type, $!body-number, $!module, $!method";

      # get the object and test for existence of method
      my $object = $!globals.objects{$!module}
        if $!globals.objects{$!module}:exists;

      if $object.defined {
        die X::SemiXML.new(
          :message(
            "Method $!method in module $!module ($object.^name()) not defined"
          )
        ) unless $object.^can($!method);
      }

      else {
        die X::SemiXML.new(:message("Module $!module not defined"));
      }

      my XML::Element $parent .= new(:name<sxml::parent-element>);
      my XML::Element $result = $object."$!method"(
        $parent, $!attributes, :$!content-body
      );
      $!content-body.after($_) for $result.nodes.reverse;
      $!content-body.remove;
    }
}}
  }

  #-----------------------------------------------------------------------------
  method perl ( --> Str ) {

    my Str $e;
    my Str $modifiers = '(';
    $modifiers ~= $!inline ?? 'i ' !! '¬i '; # inline or block
    $modifiers ~= $!noconv ?? '¬e ' !! 'e '; # transform or not
    $modifiers ~= $!keep ?? 'k ' !! '¬k ';   # keep as typed or compress
    $modifiers ~= $!close ?? 's ' !! '¬s ';  # self closing or not

    $modifiers ~= '| ';

    $modifiers ~= 'F' if $!node-type ~~ SemiXML::Fragment;
    $modifiers ~= 'E' if $!node-type ~~ SemiXML::Plain;
    $modifiers ~= 'D' if $!node-type ~~ SemiXML::CData;
    $modifiers ~= 'P' if $!node-type ~~ SemiXML::PI;
    $modifiers ~= 'C' if $!node-type ~~ SemiXML::Comment;

    $modifiers ~= ')';

    my Str $attrs = '';
    for $!attributes.kv -> $k, $v {
      $attrs ~= "$k=\"$v\" ";
    }

    if $!node-type ~~ any(
       SemiXML::Plain, SemiXML::CData, SemiXML::PI, SemiXML::Comment
    ) {
      $e = [~] '$', $!name, " $modifiers", " $attrs", ' ...';
    }

    else {
      $e = [~] '$!', $!module, '.', $!method, " $modifiers", " $attrs", ' ...';
    }

    $e
  }

  #----[ private stuff ]--------------------------------------------------------
  method !process-FTable ( ) {

    my Hash $ftable = $!globals.refined-tables<F> // {};
    $!inline = $!name ~~ any(|@($ftable<inline> // []));
    $!noconv = $!name ~~ any(|@($ftable<no-conversion> // []));
    $!keep = $!name ~~ any(|@($ftable<space-preserve> // []));
    $!close = $!name ~~ any(|@($ftable<self-closing> // []));
  }

  #-----------------------------------------------------------------------------
  method !process-attributes ( ) {

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
  method !set-attributes ( ) {

    $!attributes<sxml:inline> = $!inline ?? 1 !! 0;
    $!attributes<sxml:noconv> = $!noconv ?? 1 !! 0;
    $!attributes<sxml:keep> = $!keep ?? 1 !! 0;
    $!attributes<sxml:close> = $!close ?? 1 !! 0;
  }

  #-----------------------------------------------------------------------------
  # normal node
  method !plain-xml (
    $parent, Bool :$inline = False, Bool :$noconv = False,
    Bool :$keep = False, Bool :$close = False
  ) {

note "$!node-type, $!body-number, $!name";
    # new xml element
    my XML::Element $xml-node .= new(:$!name);
    self!copy-attributes($parent);

    # append node to the parent node
    $parent.append($xml-node);

    # when the node is self closing we do not need to process
    # the content of the body
    self!copy-nodes( $xml-node, :$inline, :$noconv, :$keep, :$close)
      unless $!close;
  }

  #-----------------------------------------------------------------------------
  # comment node
  method !comment-xml ( $parent ) {

note "$!node-type, $!body-number, $!name, $parent.name()";

    my XML::Element $x .= new(:name<x>);
    self!copy-nodes( $x, :keep);
    my XML::Comment $c .= new(:data($x.nodes));

    $parent.append($c);
  }

  #-----------------------------------------------------------------------------
  # CData node
  method !cdata-xml ( $parent ) {

note "$!node-type, $!body-number, $!name, $parent.name()";

    my XML::Element $x .= new(:name<x>);
    self!copy-nodes( $x, :keep);
    my XML::CDATA $c .= new(:data($x.nodes));

    $parent.append($c);
  }

  #-----------------------------------------------------------------------------
  # PI node
  method !pi-xml ( $parent ) {

note "$!node-type, $!body-number, $!name, $parent.name()";

    my XML::Element $x .= new(:name<x>);
    self!copy-nodes( $x, :keep);
    my Str $target = ($!attributes<target> // 'no-target').Str;
    my XML::PI $c .= new(
      :data( SemiXML::XMLText.new(:text($target)), |$x.nodes)
    );

    $parent.append($c);
  }

  #-----------------------------------------------------------------------------
  # set attributes
  method !copy-attributes ( $xml-node ) {

    for $!attributes.kv -> $k, $v {
      $xml-node.set( $k, ~$v);
    }
  }

  #-----------------------------------------------------------------------------
  method !copy-nodes ( $parent, Bool :$inline is copy = False,
    Bool :$noconv is copy = False, Bool :$keep is copy = False,
    Bool :$close is copy = False
  ) {

    if $!nodes.elems {
      for @$!nodes -> $node {
        if $node.node-type !~~ SemiXML::Text {

#TODO what to do if an attribute turns off an option?
          # inherit from parent nodes
          $inline = ($inline or $!inline);
          $noconv = ($noconv or $!noconv);
          $keep = ($keep or $!keep);
          $close = ($close or $!close);
        }

        $node.xml( $parent, :$inline, :$noconv, :$keep, :$close);
      }
    }

    else {
      $parent.append(SemiXML::XMLText.new(:text('')));
    }
  }
}
