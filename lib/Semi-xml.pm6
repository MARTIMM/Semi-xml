use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#---------------------------------------------------------------------------
#
class Semi-xml:ver<0.4.0> does Semi-xml::Actions {

  my Hash $styles;
  my Hash $configuration;

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
    return self.get-xml-text;
  }

  #-------------------------------------------------------------------------
  #
  method save ( Str :$filename ) {
    my $document = self.get-xml-text;
say $filename;
    spurt( $filename, $document);
  }

  #-------------------------------------------------------------------------
  #
  method get-xml-text ( ) {
    my Str $document = '';
    my $o = $configuration<options>;
    my $root-element = $!xml-document.root.name;
    
    if ?$root-element {
      if $o<xml-prelude><show> {
        $document = [~] '<?xml version="', $o<xml-prelude><version>, '"';
        if ?$o<xml-prelude><encoding> {
          $document = [~] $document,
                          ' encoding="',
                          $o<xml-prelude><encoding>,
                          '"';
        }

        $document ~= "?>\n";
      }

      if $o<doctype><show> {
        $document = [~] $document, '<!DOCTYPE ',
                        $root-element,
                        $o<doctype><doc-definition> // '',
                        ">\n";
      }

      $document ~= $!xml-document.root;
    }
    
    return $document;
  }
}

#---------------------------------------------------------------------------
#
multi sub prefix:<~>( Semi-xml $x --> Str ) {
  return ~$x.get-xml-text;
}

