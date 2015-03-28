use v6;

BEGIN {
  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
}

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
#say "CB 0: {$content-body}";
#say "CB 1: {$parent.^name}, {$parent.name}";
      $content-body.remove;

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
            # fail if thare are more than one top level elements.
            #
            my Semi-xml $x .= new;
            
            # When parsing another new piece of text, this result will be placed
            # next to a previously prepared sibling 'PLACEHOLDER-ELEMENT' of
            # which the contents is given to this method as @content-body
            #
            $x.parse(:content("\$XX-XX-XX\[$sxml-text\]"));

            # Replace all elements below the container tag XX-XX-XX
            # in the parent element of the container.
            #
            for $parent.nodes -> $node {
              if $node.can('name') {
#say "CB 2: $node.name";
                if $node.name eq 'XX-XX-XX' {
                  $parent.append($_) for $node.nodes;

#say "CB 3: remove {$node.name}";
                  $node.remove;
                  last;
                }
              }
            }
          }

          else {
            say "Reference '$reference' not found";
          }
        }

        default {
          say "Type $type not recognized with \$!include";
        }
      }
    }
  }
}
