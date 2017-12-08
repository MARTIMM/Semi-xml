use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

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

    my $type = ($attrs<type> // 'reference').Str;
    my $reference = ~$attrs<reference> // '';

    # make reference in reference to the parsed sxml file
    if $reference !~~ m/^ '/'/ {
      $reference =
        $SemiXML::Sxml::filename.IO.absolute.IO.dirname ~
        "/$reference";
    }

    # check if readable
    if $reference.IO !~~ :r {

      die "Reference '$reference' not found";
    }


    my $document;
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
        my $e = $x.parse(:content("\$XX-XX-XX [ $sxml-text ]"));

        # move nodes to the parent node
        $parent.insert($_) for $x.root-element.nodes.reverse;
      }

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

      default {
        die "Type $type not recognized with \$!include";
      }
    }

    $parent;
  }
}
