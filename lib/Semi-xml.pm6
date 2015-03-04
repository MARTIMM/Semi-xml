use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#---------------------------------------------------------------------------
#
class Semi-xml:ver<0.4.0> does Semi-xml::Actions {

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

    Semi-xml::Grammar.parse( $content, :actions(self));
  }

  #-------------------------------------------------------------------------
  #
  method Str ( --> Str ) {
    return ~$!xml-document;
  }

  #-------------------------------------------------------------------------
  #
  method save ( Str :$filename ) {
    $!xml-document.save($filename);
  }
}

#---------------------------------------------------------------------------
#
multi sub prefix:<~>( Semi-xml $x --> Str ) {
  return ~$x.xml-document;
}

