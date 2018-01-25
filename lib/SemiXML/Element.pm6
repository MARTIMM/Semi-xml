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

  has Hash $.attributes;

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( Str:D :$!name!, Hash :$!attributes = {} ) {
    $!node-type = SemiXML::Plain;
    $!globals .= instance;
    $!nodes = [];

    # a normal element(Plain) might have entries in the FTable configuration
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
    $!node-type = SemiXML::Method;
    $!globals .= instance;
    $!nodes = [];

    self!process-attributes;

    # keep can be overruled by a global keep
    $!keep = $!globals.keep;
  }

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

  #-----------------------------------------------------------------------------
  method append ( SemiXML::Node:D $node ) {

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
note "X: $!name, $!node-type, $parent, $keep";

    given $!node-type {
      when any( SemiXML::Fragment, SemiXML::Plain) {
        my XML::Element $this-node-xml .= new(:$!name);
        for $!attributes.kv -> $k, $v {
          $this-node-xml.set( $k, ~$v);
        }

        $parent.append($this-node-xml);

        unless $!close {
          if $!nodes.elems {
            for @$!nodes -> $node {
              if $node.node-type ~~ SemiXML::Text {
                next if $close;
              }

              else {
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
    }
  }

  #-----------------------------------------------------------------------------
  method perl ( --> Str ) {

    my Str $e;
    my Str $modifiers = '(';
    $modifiers ~= $!inline ?? 'i ' !! '¬i '; # inline or block
    $modifiers ~= $!noconv ?? '¬e ' !! 'e ';  # escape transform or not
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

    if $!node-type ~~ SemiXML::Plain {
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
          $!attributes{$key}:delete;
        }

        when /^ sxml ':' noconv / {
          $!noconv = $!attributes{$key}.Int.Bool;
          $!attributes{$key}:delete;
        }

        when /^ sxml ':' keep / {
          $!keep = $!attributes{$key}.Int.Bool;
          $!attributes{$key}:delete;
        }

        when /^ sxml ':' close / {
          $!close = $!attributes{$key}.Int.Bool;
          $!attributes{$key}:delete;
        }

        when /^ sxml ':' / {
          $!attributes{$key}:delete;
        }
      }
    }
  }
}
