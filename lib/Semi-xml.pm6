use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#-------------------------------------------------------------------------------
#
class Semi-xml:ver<0.5.0> does Semi-xml::Actions {

  my Hash $styles;
  my Hash $configuration;
  my Hash $defaults = {
    options => {
      doctype => {
        show => 0,
        definition => '',
        entities => [],
      },

      xml-prelude => {
        show => 0,
        version => '1.0',
        encoding => 'UTF-8',
      }
    },

    output => {
      # Filename of program is saved without extension
      #
      filename => ($*PROGRAM ~~ m/(.*?)\.<{$*PROGRAM.IO.extension}>$/[0]),
      fileext => 'xml',
    }
  };

  #-----------------------------------------------------------------------------
  #
  method parse-file ( Str :$filename ) {
    if $filename.IO ~~ :r {
      my $text = slurp($filename);
      return self.parse( :content($text) );
    }
  }

  #-----------------------------------------------------------------------------
  #
  method parse ( :$content is copy ) {

say "D: $defaults<output><filename>";

    # Remove comments
    #
    $content ~~ s:g/<-[\\]>\#.*?$$//;
    $content ~~ s/^\#.*?$$\n//;
    $content ~~ s/^\s+//;
    $content ~~ s/\s+$//;

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

  #-----------------------------------------------------------------------------
  #
  method Str ( --> Str ) {
    return self.get-xml-text;
  }

  #-----------------------------------------------------------------------------
  #
  method save ( Str :$filename ) {
    my $document = self.get-xml-text;
    spurt( $filename, $document);
  }

  #-----------------------------------------------------------------------------
  #
  method get-xml-text ( ) {
    my Str $document = '';
    
    # Get the top element name
    #
    my $root-element = $!xml-document.root.name;
    
    # If there is one, try to generate the xml
    #
    if ?$root-element {
      
      # Pick the config from the user role or that from the files prelude
      #
      my $o = $!config<options>:exists ?? $!config<options>
                                       !! $configuration<options>
                                       ;
      my $do = $defaults<options>;

      # Check if xml prelude must be shown
      #
      my $okey = $o<xml-prelude><show>:exists ?? $o<xml-prelude><show>
                                              !! $do<xml-prelude><show>
                                              ;
      if $okey {
        $o<xml-prelude><version> //= $do<xml-prelude><version>;
        $document = "<?xml version=\"{$o<xml-prelude><version>}\"";

        ?$o<xml-prelude><encoding> //= $do<xml-prelude><encoding>;
        $document ~= " encoding=\"{$o<xml-prelude><encoding>}\"?>\n";
      }

      # Check if doctype must be shown
      #
      $okey = $o<doctype><show>:exists ?? $o<doctype><show>
                                       !! $do<doctype><show>
                                       ;
      if $okey {
        $o<doctype><definition> //= $do<doctype><definition>;
        my $ws = $o<doctype><definition> ?? ' ' !! '';
        $document ~= "<!DOCTYPE $root-element$ws"
                   ~ "{$o<doctype><definition>}>\n"
                   ;
      }

      $document ~= $!xml-document.root;
    }
    
    return $document;
  }
}

#-------------------------------------------------------------------------------
#
multi sub prefix:<~>( Semi-xml $x --> Str ) {
  return ~$x.get-xml-text;
}

