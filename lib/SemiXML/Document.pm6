use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Globals;
use SemiXML::Node;
use SemiXML::Element;
use XML;

#-------------------------------------------------------------------------------
class Document {

  has SemiXML::Globals $!globals;

  # the root should only have one element. when there are more, convert
  # the result into a fragment.
  has SemiXML::Element $.root;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!globals .= instance;

    # initialize root node and place in the array. this node will never be
    # overwritten.
    $!root .= new(
      :name<sxml:fragment>,
      :attributes({'xmlns:sxml' => 'https://github.com/MARTIMM/Semi-xml'})
    );
  }

  #-----------------------------------------------------------------------------
  method xml2sxml ( Str:D :$xml-text --> SemiXML::Element ) {

    # overwrite existing tree and initialize root node.
    $!root .= new(
      :name<sxml:fragment>,
      :attributes({'xmlns:sxml' => 'https://github.com/MARTIMM/Semi-xml'})
    );

    self!process-xml( from-xml($xml-text), $!root)
  }

  #-----------------------------------------------------------------------------
  # always perform xml transforms when asked for xml-text
  method xml-text ( --> Str ) {

#note "Tree: $!root";
    my Str $xml-text = '';

    if $!root.nodes.elems == 0 {
      $xml-text = $!root.xml;
    }

    elsif $!root.nodes.elems == 1 {
      self!set-namespaces($!root.nodes[0]);
      $xml-text = $!root.nodes[0].xml;
    }

    elsif $!root.nodes.elems > 1 {
      if $!globals.frag {
        self!set-namespaces($!root.nodes[0]);
        $xml-text = $!root.xml;
      }

      else {
        die X::SemiXML::Core.new(
          :message(
            "Too many nodes on top level. Maximum allowed nodes is one"
          )
        )
      }
    }

    $xml-text
  }

  #-----------------------------------------------------------------------------
  # always perform xml transforms when asked for xml-text
  method root-name ( --> Str ) {

    my $root-name = '';
    if $!root.nodes.elems == 0 {
      $root-name = $!root.name;
    }

    elsif $!root.nodes.elems == 1 {
      $root-name = $!root.nodes[0].name;
    }

    elsif $!root.nodes.elems > 1 {
      if $!globals.frag {
        $root-name = $!root.name;
      }

      else {
        die X::SemiXML::Core.new(
          :message(
            "Too many nodes on top level. Maximum allowed nodes is one"
          )
        )
      }
    }

    $root-name
  }

  #----[ private stuff ]--------------------------------------------------------
  method !process-xml ( XML::Node $n, SemiXML::Node $parent ) {

    given $n {
      when XML::CDATA {
        $parent.append( 'sxml:cdata', :text(.data));
      }

      when XML::Comment {
        $parent.append( 'sxml:comment', :text(.data));
      }

      when XML::PI {
        $parent.append( 'sxml:pi', :text(.data));
      }

      when XML::Text {
        $parent.append(:text(.text));
      }

      when XML::Document {
        self!process-xml( .root, $parent);
      }

      when XML::Element {
        my SemiXML::Node $sxml-node = $parent.append(
          .name, :attributes({|.attribs})
        );

        for $n.nodes -> $node {
          self!process-xml( $node, $sxml-node);
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  # set namespaces on the element
  method !set-namespaces ( SemiXML::Element $element ) {

    # add namespaces xmlns
    my Hash $refIn = $!globals.refined-tables<DN> // {};

    for $refIn.keys -> $ns {
      if $ns eq 'default' {
        $element.attributes<xmlns> = $refIn{$ns};
      }

      else {
        $element.attributes<xmlns:$ns> = $refIn{$ns};
      }
    }
  }
}
