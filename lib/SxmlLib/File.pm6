use v6.c;

use Semi-xml;
use XML;

# Package cannot be placed in Semi-xml/Lib and named File.pm6. Evaluation seems
# to fail not finding the symbol &File when doing so.
#
package SxmlLib:auth<https://github.com/MARTIMM> {

  class File {
    has Hash $.symbols = {};

    #---------------------------------------------------------------------------
    #
    method include ( XML::Element $parent,
                     Hash $attrs,
                     XML::Node :$content-body
                   ) {

      my $type = $attrs<type> // 'reference';
      my $reference = $attrs<reference> // '';
      my $document;
      given $type {
        when 'reference' {

        }

        when 'include' {
          # Check if readable
          #
          if $reference.IO ~~ :r {

            # Read the content
            #
            my $sxml-text = slurp($reference);

            # Create the parser object and parse its content. Important to
            # encapsulate the content in another tag because parsing will
            # fail if there are more than one top level elements.
            #
            my Semi-xml::Sxml $x .= new;

            # When parsing another new piece of text, this result will be placed
            # next to a previously prepared sibling 'PLACEHOLDER-ELEMENT' of
            # which the contents is given to this method as @content-body
            #
            # The top level node xx-xx-xx is used to be sure there is only one
            # element at the top when parsing starts.
            #
            my $e = $x.parse(:content("\$XX-XX-XX [ $sxml-text ]"));

            # Search for the PLACEHOLDER-ELEMENT child under the parent node
            #
            my XML::Node $placeholder;
            for $parent.nodes -> $node {
              if $node ~~ XML::Element and $node.name eq 'PLACEHOLDER-ELEMENT' {
                $placeholder = $node;
              }
            }

            # Search for node XX-XX-XX and move all nodes below that container
            # just after the $placeholder element found above.
            #
            my $node = $x.root-element;
            while $node.nodes.elems {
              # Take the last first because next it is inserted after the
              # placeholder which then pushed to the back by the next
              # element
              #
              my $fnode = $node.nodes.pop;
              $parent.after( $placeholder, $fnode);
            }
          }

          else {
            die "Reference '$reference' not found";
          }
        }

        default {
          die "Type $type not recognized with \$!include";
        }
      }

#      $content-body.remove;
    }
  }
}
