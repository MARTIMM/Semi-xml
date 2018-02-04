use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Sxml;
use SemiXML::Element;

#-------------------------------------------------------------------------------
class File {

  has Hash $.symbols = {};
  has SemiXML::Globals $!globals .= instance;

  #-----------------------------------------------------------------------------
  method include ( SemiXML::Element $m --> Array ) {

    my SemiXML::Globals $globals .= instance;

    my $type = ($m.attributes<type> // 'reference').Str;
    my $reference = ~$m.attributes<reference> // '';

    # make reference to the parsed sxml file absolute if relative
    unless $reference ~~ m/^ '/'/ {
      $reference =
        $globals.filename.IO.absolute.IO.dirname ~
        "/$reference";
    }

    # check if readable
    if $reference.IO !~~ :r {
      die "Reference '$reference' not found";
    }

    my Array $element-array = [];
    given $type {

#TODO get data using url reference
      when 'reference' {

      }

      # include sub document from file
      when 'include' {

        # read the content
        my $sxml-text = slurp($reference);

        # new parser object
        my SemiXML::Sxml $x .= new;

        # the top level node xx-xx-xx is used to be sure there is only one
        # element at the top when parsing starts.
        $x.parse( :content($sxml-text), :tree, :trace, :frag,
          config => {
            T => { :parse }
          }
        );

        my SemiXML::Node $tree = $x.sxml-tree;
#note "Tree: $tree";
        for $tree.nodes.reverse -> $node {
#note "Node: $node";
          $element-array.unshift: $node;
        }

        # move nodes to the array

        #$x.root-element.nodes.reverse;
      }
#`{{
      # include sub document from file
      when 'include-xml' {

        # check if readable
        if $reference.IO ~~ :r {
          # new xml object
          my XML::Document $xml = from-xml-file($reference);

          # move nodes to the parent node
          $parent.insert($xml.root);
        }
      }
}}

      default {
        die "Type $type not recognized with \$!include";
      }
    }

    $element-array
  }
}
