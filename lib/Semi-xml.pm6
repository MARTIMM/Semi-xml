use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#-------------------------------------------------------------------------------
#
class Semi-xml:ver<0.14.2>:auth<https://github.com/MARTIMM> {

  our $debug = False;

  has Semi-xml::Actions $.actions;
  has Hash $.styles;
  has Hash $.configuration;

  my Hash $defaults = {
    option => {
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
    $!actions = Semi-xml::Actions.new(:$init);
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
#    if $!actions.defined {
#      $sub-actions = Semi-xml::Actions.new();
#      $sts = Semi-xml::Grammar.parse( $content, :actions($sub-actions));
#      Semi-xml::Grammar.parse( $content, :actions($sub-actions));
#    }

#    else {
#say "A0: {$!actions.get-document.WHERE}";
#say "A1: $content";
      Semi-xml::Grammar.parse( $content, :actions($!actions));
#say "A2: {$!actions.get-document}";
#    }

#say "Sts: {$sts.WHAT}, {$sts.perl}";
#    die "Failure parsing the content" unless $sts;
  }

  #-----------------------------------------------------------------------------
  #
  method root-element ( --> XML::Element ) {
    return $!actions.get-document.root;
  }

  #-----------------------------------------------------------------------------
  #
  method Str ( --> Str ) {
    return self.get-xml-text;
  }

  #-----------------------------------------------------------------------------
  #
  method save ( Str :$filename is copy, Str :$run-code ) {
    my Array $cfgs = [ $!actions.config<output>,
                       $!configuration<output>,
                       $defaults<output>
                     ];

    my $document = self.get-xml-text;

    if $run-code.defined {
#say "Run $run-code";
      my $cmd = self.get-option( :section('output'),
                                 :sub-section('program'),
                                 :option($run-code)
                               );

#-----
# Temporary solution for command
#
if !$filename.defined {
  $filename = self.get-option( $cfgs, 'filename');
  my $fileext = self.get-option( $cfgs, 'fileext');

  $filename ~= ".$fileext";
}

if $filename !~~ m@'/'@ {
  my $filepath = self.get-option( $cfgs, 'filepath');
  $filename = "$filepath/$filename" if $filepath;
}

spurt( $filename, $document);
#say "save to $filename";
#-----

      if $cmd.defined {
        $cmd ~~ s:g/\n/ /;
        $cmd ~~ s:g/\s+/ /;
        $cmd ~~ s/^\s*\|//;
#        my $program-io = IO::Pipe.to($cmd);
#say "IO: $program-io";

        # No pipe to executable at the moment so take a different route...
        #
#        spurt( '.-temp-file-to-store-command-.sh', "cat $filename | $cmd");
#say "Cmd: cat $filename | $cmd";
        shell("cat $filename | $cmd");
      }

      else {
        say "Code '$run-code' to select command not found";
        exit(0);
      }
    }

    else {
      if !$filename.defined {
        $filename = self.get-option( $cfgs, 'filename');
        my $fileext = self.get-option( $cfgs, 'fileext');

        $filename ~= ".$fileext";
      }

      if $filename !~~ m@'/'@ {
        my $filepath = self.get-option( $cfgs, 'filepath');
        $filename = "$filepath/$filename" if $filepath;
      }

      spurt( $filename, $document);
    }
  }

  #-----------------------------------------------------------------------------
  #
  method get-xml-text ( ) {
    # Get the top element name
    #
    my $root-element = $!actions.get-document.root.name;
    $root-element ~~ s/^(<-[:]>+\:)//;

    my Str $document = '';

    # If there is one, try to generate the xml
    #
    if ?$root-element {
      # Check if xml prelude must be shown
      #
      my Array $cfgs = [ $!actions.config<option><xml-prelude>,
                         $!configuration<option><xml-prelude>,
                         $defaults<option><xml-prelude>
                       ];
#say "XO: {? self.get-option( $cfgs, 'show')}";
      if ? self.get-option( $cfgs, 'show') {
        my $version = self.get-option( $cfgs, 'version');
        my $encoding = self.get-option( $cfgs, 'encoding');

        $document = "<?xml version=\"$version\"";
        $document ~= " encoding=\"$encoding\"?>\n";
      }

      # Check if doctype must be shown
      #
      $cfgs = [ $!actions.config<option><doctype>,
                $!configuration<option><doctype>,
                $defaults<option><doctype>
              ];
      if ? self.get-option( $cfgs, 'show') {
        my $definition = self.get-option( $cfgs, 'definition');
        my $ws = $definition ?? ' ' !! '';
        $document ~= "<!DOCTYPE $root-element$ws$definition>\n";
      }

      $document ~= $!actions.get-document.root;
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
                            Str :$option = ''
                            --> Any
                          ) {
    my Array $hashes;
    for ( $!actions.config, $!configuration, $defaults) -> $h {
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

