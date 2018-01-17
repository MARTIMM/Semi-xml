use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::StringList;
use SemiXML::Body;
use XML;

#-------------------------------------------------------------------------------
class Node {

  has SemiXML::Globals $!globals;

  has SemiXML::Node $.parent;
  has Array $.nodes;
  has Array $.bodies;

  has Str $.name;
  has Str $.namespace;

  has Str $!module;
  has Str $!method;

  has Bool $.inline = False;  # inline in FTable
  has Bool $.noesc = False;   # no-escaping in FTable
  has Bool $.keep = False;    # space-preserve in FTable
  has Bool $.close = False;   # self-closing in FTable

  has SemiXML::NodeType $.type;

  has Hash $.attributes;

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( Str:D :$!name!, Hash :$!attributes = {} ) {
    $!globals .= instance;
    $!type = SemiXML::Element;
    $!nodes = [];

    # a normal element might have entries in the FTable configuration
    self!process-FTable;

    # it can be overidden by attributes
    self!process-attributes;

    # keep can be overruled by a global keep
    $!keep = $!globals.keep;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD (
    Str:D :$!module!, Str:D :$!method!, Hash :$!attributes = {}
  ) {
    $!globals .= instance;
    $!type = SemiXML::Method;
    $!nodes = [];

    self!process-attributes;

    # keep can be overruled by a global keep
    $!keep = $!globals.keep;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # can only be called from other code and cannot be used directly from
  # sxml text
  multi submethod BUILD ( Bool:D :$cdata! ) {
    $!globals .= instance;
    $!type = SemiXML::CData;
    $!nodes = [];
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD ( Bool:D :$pi! ) {
    $!globals .= instance;
    $!type = SemiXML::PI;
    $!nodes = [];
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD ( Bool:D :$comment! ) {
    $!globals .= instance;
    $!type = SemiXML::Comment;
    $!nodes = [];
  }

  #-----------------------------------------------------------------------------
  method append ( SemiXML::Node:D $node ) {

    # check node type
    if $node.type ~~ any(SemiXML::Fragment|SemiXML::Element|SemiXML::Method) {

      # search for the node first in the array
      my Bool $parent-has-node = False;
      for @($!nodes) -> $n {
        if $n === self {
          $parent-has-node = True;
          last;
        }
      }

      # add the node when not found and set the parent in the node
      unless $parent-has-node {
        $!nodes.push($node);
        $node.parent(self);
      }
    }

    else {
      die 'CData, PI and Comments can not have children';
    }
  }

  #-----------------------------------------------------------------------------
  method parent ( SemiXML::Node:D $!parent ) { }

  #-----------------------------------------------------------------------------
  method attributes ( Hash $!attributes ) {
    self!process-attributes;
  }

  #-----------------------------------------------------------------------------
  method body ( --> SemiXML::Body ) {
    my SemiXML::Body $b .= new;
    $!bodies.push($b);

    $b
  }

  #-----------------------------------------------------------------------------
  method perl ( --> Str ) {

    my Str $e;
    my Str $modifiers = '(';
    $modifiers ~= $!inline ?? 'i ' !! '¬i '; # inline or block
    $modifiers ~= $!noesc ?? '¬e ' !! 'e ';  # escape transform or not
    $modifiers ~= $!keep ?? 'k ' !! '¬k ';   # keep as typed or compress
    $modifiers ~= $!close ?? 's ' !! '¬s ';  # self closing or not

    $modifiers ~= '| ';

    $modifiers ~= 'F' if $!type ~~ SemiXML::Fragment;
    $modifiers ~= 'E' if $!type ~~ SemiXML::Element;
    $modifiers ~= 'D' if $!type ~~ SemiXML::CData;
    $modifiers ~= 'P' if $!type ~~ SemiXML::PI;
    $modifiers ~= 'C' if $!type ~~ SemiXML::Comment;

    $modifiers ~= ')';

    my Str $attrs = '';
    for $!attributes.kv -> $k, $v {
      $attrs ~= "$k=\"$v\" ";
    }

    if $!type ~~ SemiXML::Element {
      $e = [~] '$', $!name, " $modifiers", " $attrs", ' ...';
    }

    else {
      $e = [~] '$!', $!module, '.', $!method, " $modifiers", " $attrs", ' ...';
    }

    $e
  }

  #-----------------------------------------------------------------------------
  method xml ( XML::Node $parent, Bool :$keep = False ) {

#    for @$!nodes -> $node {
#      $node.xml( $parent, :$keep);
#    }
  }

  #----[ private stuff ]--------------------------------------------------------
  method !process-FTable ( ) {

    my Hash $ftable = $!globals.refined-tables<F> // {};
    $!inline = $!name ~~ any(|@($ftable<inline> // []));
    $!noesc = $!name ~~ any(|@($ftable<no-escaping> // []));
    $!keep = $!name ~~ any(|@($ftable<space-preserve> // []));
    $!close = $!name ~~ any(|@($ftable<self-closing> // []));
  }

  #-----------------------------------------------------------------------------
  method !process-attributes ( ) {

    for $!attributes.keys -> $key {
      given $key {
        when /^ sxml ':' inline / {
          $!inline = True;
          $!attributes<$key>:delete;
        }

        when /^ sxml ':' noesc / {
          $!noesc = True;
          $!attributes<$key>:delete;
        }

        when /^ sxml ':' keep / {
          $!keep = True;
          $!attributes<$key>:delete;
        }

        when /^ sxml ':' / {
          $!attributes<$key>:delete;
        }
      }
    }
  }
}
