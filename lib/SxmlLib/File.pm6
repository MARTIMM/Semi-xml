use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
class File {

  has Hash $.symbols = {};

  #-----------------------------------------------------------------------------
  method include ( XML::Element $parent,
                   Hash $attrs,
                   XML::Element :$content-body
                 ) {

    my $type = $attrs<type> // 'reference';
    my $reference = $attrs<reference> // '';
    my $document;
    given $type {

      #TODO get data using url reference
      when 'reference' {

      }

      # include sub document from file
      when 'include' {

        # check if readable
        if $reference.IO ~~ :r {

          # read the content
          my $sxml-text = slurp($reference);

          # new parser object
          my SemiXML::Sxml $x .= new;

          # the top level node xx-xx-xx is used to be sure there is only one
          # element at the top when parsing starts.
          #
          my $e = $x.parse(:content("\$|XX-XX-XX [ $sxml-text ]"));

          # move nodes to the parent node
          $parent.insert($_) for $x.root-element.nodes.reverse;
        }

        else {
          die "Reference '$reference' not found";
        }
      }

      default {
        die "Type $type not recognized with \$!include";
      }
    }
    
    $parent;
  }
}
