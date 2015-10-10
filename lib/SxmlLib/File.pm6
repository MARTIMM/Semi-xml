use v6;

#BEGIN {
#  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
#}

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
                     XML::Node :$content-body   # Ignored
                   ) {

      $content-body.remove;

      my $type = $attrs<type> // 'reference';
      my $reference = $attrs<reference> // '';
      my $document;
      given $type {
        when 'reference' {

        }

        when 'include' {
say "Include file $reference";
          # Check if readable
          #
          if $reference.IO ~~ :r {

            # Read the content
            #
            my $sxml-text = slurp($reference);
say "$sxml-text";

            # Create the parser object and parse its content. Important to
            # encapsulate the content in another tag because parsing will
            # fail if thare are more than one top level elements.
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
say "\nE = $e";

            # Search for node XX-XX-XX and move all nodes below that container
            # to the parent element of the container.
            #
say "F Parent 0: $parent, Nbr children: {$parent.nodes.elems}";
            for $parent.nodes -> $node {

              # Skip all non-element nodes like XML::Text
              #
              if $node ~~ XML::Element and $node.name eq 'XX-XX-XX' {
say "F reparent children of ", $node, ", nbr children: ", $node.nodes.elems;
                while $node.nodes.elems {
                  my $fnode = $node.nodes.shift;
say "X $fnode";
say "F reparent node: ", $fnode ~~ XML::Element ?? $fnode.name !! ~$fnode;
                  $parent.append($fnode);
say "F Parent 1: $parent, Nbr children: {$parent.nodes.elems}";
                }

                $node.remove;
                last;
              }
            }
say "F Parent 2: $parent";
#exit(0);
          }

          else {
            die "Reference '$reference' not found";
          }
        }

        default {
          die "Type $type not recognized with \$!include";
        }
      }
    }
  }
}
