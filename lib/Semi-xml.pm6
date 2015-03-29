use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#-------------------------------------------------------------------------------
#
class Semi-xml:ver<0.10.0>:auth<https://github.com/MARTIMM> {

  our $debug = False;

  has Semi-xml::Actions $actions;
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
      filepath => '.',
      filename => 'x',
      fileext => 'xml',
    },

    # To be set by sources and used by translater programs
    #
    dependencies => ''
  };

  # Calculate default filename
  #
#  $*PROGRAM ~~ m/(.*?)\.<{$*PROGRAM.IO.extension}>$/;
#  $defaults<output><filename> = ~$/[0];
  
#  my @path-spec = $*SPEC.splitpath($*PROGRAM);
#  $defaults<output><filename> = @path-spec[2];
#  $defaults<output><filename> ~~ s/$*PROGRAM.IO.extension//;
#say "PS: @path-spec[]";
  
  has Bool $!init;
  
  submethod BUILD ( Bool :$init ) {
#say "SI: {?$init}";
    $actions = Semi-xml::Actions.new(:$init);
  }

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

#    my $sts;
#    my $sub-actions;
#    if $actions.defined {
#      $sub-actions = Semi-xml::Actions.new();
#      $sts = Semi-xml::Grammar.parse( $content, :actions($sub-actions));
#      Semi-xml::Grammar.parse( $content, :actions($sub-actions));
#    }

#    else {
      Semi-xml::Grammar.parse( $content, :actions($actions));
#    }

#say "Sts: {$sts.WHAT}, {$sts.perl}";
#    die "Failure parsing the content" unless $sts;
  }

  #-----------------------------------------------------------------------------
  #
  method root-element ( --> XML::Element ) {
    return $actions.xml-document.root;
  }

  #-----------------------------------------------------------------------------
  #
  method Str ( --> Str ) {
    return self.get-xml-text;
  }

  #-----------------------------------------------------------------------------
  #
  method save ( Str :$filename is copy ) {
    my Array $cfgs = [ $actions.config<output>,
                       $!configuration<output>,
                       $defaults<output>
                     ];

    if !$filename.defined {
      $filename = self.get-option( $cfgs, 'filename');
      my $fileext = self.get-option( $cfgs, 'fileext');

      $filename ~= ".$fileext";
    }

#say "F 0: $filename";
    if $filename !~~ m@'/'@ {
      my $filepath = self.get-option( $cfgs, 'filepath');
#say "F 1: $filepath";
      $filename = "$filepath/$filename";
    }

    my $document = self.get-xml-text;
    spurt( $filename, $document);
  }

  #-----------------------------------------------------------------------------
  #
  method get-xml-text ( ) {
    # Get the top element name
    #
    my $root-element = $actions.xml-document.root.name;

    my Str $document = '';

    # If there is one, try to generate the xml
    #
    if ?$root-element {
      # Check if xml prelude must be shown
      #
      my Array $cfgs = [ $actions.config<options><xml-prelude>,
                         $!configuration<options><xml-prelude>,
                         $defaults<options><xml-prelude>
                       ];
      if self.get-option( $cfgs, 'show') {
        my $version = self.get-option( $cfgs, 'version');
        my $encoding = self.get-option( $cfgs, 'encoding');

        $document = "<?xml version=\"$version\"";
        $document ~= " encoding=\"$encoding\"?>\n";
      }

      # Check if doctype must be shown
      #
      $cfgs = [ $actions.config<options><doctype>,
                $!configuration<options><doctype>,
                $defaults<options><doctype>
              ];
      if self.get-option( $cfgs, 'show') {
        my $definition = self.get-option( $cfgs, 'definition');
        my $ws = $definition ?? ' ' !! '';
        $document ~= "<!DOCTYPE $root-element$ws$definition>\n";
      }

      $document ~= $actions.xml-document.root;
    }

    return $document;
  }

  #-----------------------------------------------------------------------------
  #
  multi method get-option ( Array $hashes, Str $option --> Any ) {
    for $hashes.list -> $h {
      if $h{$option}:exists {
        return $h{$option};
      }
    }

    return Any;
  }

  #-----------------------------------------------------------------------------
  #
  multi method get-option ( Str :$section = '',
                            Str :$sub-section = '',
                            Str :$option = '';
                            --> Any
                          ) {
    my Array $hashes;
    for ( $actions.config, $!configuration, $defaults) -> $h {
      if $h{$section}:exists {
        my $e = $h{$section};

        if $e{$sub-section}:exists {
          $hashes.push($e{$sub-section});
        }

        else {
          $hashes.push($e);
        }
      }
    }
    
    for $hashes.list -> $h {
      if $h{$option}:exists {
        return $h{$option};
      }
    }

    return Any;
  }
}

#-------------------------------------------------------------------------------
#
multi sub prefix:<~>( Semi-xml $x --> Str ) {
  return ~$x.get-xml-text;
}

