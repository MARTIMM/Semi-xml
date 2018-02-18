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

#TODO add a method to load parts like xpointer looking for fragments
#TODO add a method to select lines like in FixedLayout module for docbook
  #-----------------------------------------------------------------------------
  method include ( SemiXML::Element $m ) {

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

    # read the content and parse
    my $sxml-text = slurp($reference);
    my SemiXML::Sxml $x .= new;
    $x.parse( :content($sxml-text), :!trace, :frag,
      config => {
        T => { :parse }
      }
    );

    # get the node tree and insert tree after this one
    my SemiXML::Node $tree = $x.sxml-tree;


    given $type {
#TODO get data using url reference
      when 'reference' {

      }

      # include sub document from file
      when 'include-all' {
        $m.after($tree);
        $x.done;
      }

      when 'include' {
        $m.after($_) for $tree.nodes.reverse;
        $x.done;
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
        die "Type $type not recognized with include";
      }
    }
  }
}
