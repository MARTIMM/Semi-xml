use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#-------------------------------------------------------------------------------
#
class Semi-xml:ver<0.5.1> does Semi-xml::Actions {

  has Hash $.styles;
  has Hash $.configuration;
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
      filename => '',
      fileext => 'xml',
    }
  };

  # Calculate default filename
  #
  $*PROGRAM ~~ m/(.*?)\.<{$*PROGRAM.IO.extension}>$/;
  $defaults<output><filename> = ~$/[0];

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

    # Remove comments
    #
    $content ~~ s:g/<-[\\]>\#.*?$$//;
    $content ~~ s/^\#.*?$$\n//;
    $content ~~ s/^\s+//;
    $content ~~ s/\s+$//;

#say "C: $content";

    # Get user introduced attribute information
    #
    for self.^attributes -> $class-attr {
      given $class-attr.name {
        when '$!styles' {
          $!styles = $class-attr.get_value(self);
        }

        when '$!configuration' {
          $!configuration = $class-attr.get_value(self);
        }
      }
    }

#say "P: ", $!styles, ', ', $!configuration;

    Semi-xml::Grammar.parse( $content, :actions(self));
  }

  #-----------------------------------------------------------------------------
  #
  method Str ( --> Str ) {
    return self.get-xml-text;
  }

  #-----------------------------------------------------------------------------
  #
  method save ( Str :$filename is copy ) {
    my Array $cfgs = [ $!config<output>,
                       $!configuration<output>,
                       $defaults<output>
                     ];

    if !$filename.defined {
      $filename = self.get-option( $cfgs, 'filename');
      my $fileext = self.get-option( $cfgs, 'fileext');

      $filename ~= ".$fileext";
    }
    
    my $document = self.get-xml-text;
    spurt( $filename, $document);
  }

  #-----------------------------------------------------------------------------
  #
  method get-option ( Array $hashes, Str $option --> Any ) {
    for $hashes.list -> $h {
      if $h{$option}:exists {
        return $h{$option}
      }
    }
    
    return Any;
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
                                       !! $!configuration<options>
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

if 0 {
      if ! $!xml-document.root.can('mt-string') {
        my $how = $!xml-document.root.HOW;
        $how.add_method(
          $!xml-document.root,
          'mt-string',
          method ( ) {
            return self.Str();
          }
        );
      }

      $document ~= $!xml-document.root.mt-string();
}

if 0 {
      if 1 { #! XML::Text.^find_method('Str') {
say 'Change it';
        XML::Text.^add_method(
          'Str',
          method ( ) {
            return self.text;
          }
        );
      }
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

