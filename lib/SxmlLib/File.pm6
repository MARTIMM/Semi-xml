use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Globals;
use SemiXML::Sxml;
use SemiXML::Element;

#-------------------------------------------------------------------------------
class File {

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

    # read the content
    my $sxml-text = slurp($reference);

    given $type {
#TODO get data using url reference
      when 'reference' {

      }

      # include sub document from file
      when 'include-all' {
        my SemiXML::Sxml $x .= new;
        $x.parse( :content($sxml-text), :!trace, :frag,
          config => {
            T => { :parse }
          }
        );

        # get the node tree and insert tree after this one
        my SemiXML::Node $tree = $x.sxml-tree;

        $m.after($tree);
        $x.done;
      }

      when 'include' {
        my SemiXML::Sxml $x .= new;
        $x.parse( :content($sxml-text), :!trace, :frag,
          config => {
            T => { :parse }
          }
        );

        # get the node tree and insert tree after this one
        my SemiXML::Node $tree = $x.sxml-tree;

        $m.after($_) for $tree.nodes.reverse;
        $x.done;
      }

      # include sub document from file
      when 'include-xml' {

        # bind to other name because this will be xml instead of sxml
        my Str $xml-text := $sxml-text;
        $xml-text ~~ s/'<?xml' <-[\?]>* '?>'//;

        # inject xml into sxml:xml element. check if attribute to-sxml is set
        my Hash $attributes = {};
        $attributes<to-sxml> = $m.attributes<to-sxml>:exists ?? 1 !! 0;
        my SemiXML::Element $x .= new( :name<sxml:xml>, :$attributes);
        $x.append(:text($sxml-text));
        $m.before($x);
      }

      default {
        die "Type $type not recognized with include";
      }
    }
  }
}
