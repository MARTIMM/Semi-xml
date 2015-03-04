use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#our $actions = Semi-xml::Actions.new();

#---------------------------------------------------------------------------
#
class Semi-xml:ver<0.4.0> {

  has Semi-xml::Actions $actions = Semi-xml::Actions.new();

  #-------------------------------------------------------------------------
  #
  method parse-file ( Str :$filename ) {
    if $filename.IO ~~ :r {
      my $text = slurp($filename);
      return self.parse( :content($text) );
    }
  }

  #-------------------------------------------------------------------------
  #
  method parse ( :$content is copy ) {

    my Hash $styles;
    my Hash $configuration;

    # Remove comments
    #
    $content ~~ s:g/<-[\\]>\#.*?$$//;

    # Get user introduced attribute information
    #
    for self.^attributes -> $class-attr {
      given $class-attr.name {
        when '$!styles' {
          $styles = $class-attr.get_value(self);
        }

        when '$!configuration' {
          $configuration = $class-attr.get_value(self);
        }
      }
    }

#say "P: ", $styles, ', ', $configuration;

#    my Semi-xml::Actions $actions .= new();
    Semi-xml::Grammar.parse( $content, :actions($actions));
#    Semi-xml::Grammar.subparse( $content, :actions($actions));
  }

  #-------------------------------------------------------------------------
  #
  method Str ( --> Str ) {
    return ~$actions.xml-document;
  }

  #-------------------------------------------------------------------------
  #
  method save ( Str :$filename ) {
    $actions.xml-document.save($filename);
  }
}

#---------------------------------------------------------------------------
#
multi sub prefix:<~>( Semi-xml $x --> Str ) {
  return ~$x.actions.xml-document;
}

