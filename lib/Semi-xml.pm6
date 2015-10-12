use v6;

use Semi-xml::Grammar;
use Semi-xml::Actions;

#-------------------------------------------------------------------------------
#
package Semi-xml:ver<0.17.0>:auth<https://github.com/MARTIMM> {

  class Sxml {

    our $debug = False;

    has Semi-xml::Actions $.actions;
    has Hash $.styles;
    has Hash $.configuration is rw;

    has Hash $!defaults = {
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
        },

        http-header => {
          show => 0,
        },
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
  #  $!defaults<output><filename> = ~$/[0];

  #  my @path-spec = $*SPEC.splitpath($*PROGRAM);
  #  $!defaults<output><filename> = @path-spec[2];
  #  $!defaults<output><filename> ~~ s/$*PROGRAM.IO.extension//;
  #say "PS: @path-spec[]";

    submethod BUILD ( Bool :$init ) {
      $!actions .= new(:$init);
    }

    #---------------------------------------------------------------------------
    #
    method parse-file ( Str :$filename ) {
      if $filename.IO ~~ :r {
        $!actions .= new(:init);
        my $text = slurp($filename);
        return self.parse(:content($text));
      }

      else {
        die "Filename $filename not readable";
      }
    }

    #---------------------------------------------------------------------------
    #
    method parse ( :$content is copy ) {

      # Remove comments, trailing and leading spaces
      #
  #    $content ~~ s:g/<-[\\]>\#.*?$$//;
  #    $content ~~ s/^\#.*?$$\n//;
  #say "\nContent;\n$content\n\n";
      $content ~~ s/^\s+//;
      $content ~~ s/\s+$//;

      # Get user introduced attribute information
      #
      for self.^attributes -> $class-attr {
        given $class-attr.name {
          when '$!user-styles' {
            $!styles = $class-attr.get_value(self);
          }

          when '$!user-configuration' {
            $!configuration = $class-attr.get_value(self);
          }
        }
      }

      # Parse the content. Parse can be recursively called
      #
      return Semi-xml::Grammar.parse( $content, :actions($!actions));
    }

    #---------------------------------------------------------------------------
    #
    method root-element ( --> XML::Element ) {
      return $!actions.get-document.root;
    }

    #---------------------------------------------------------------------------
    #
    method Str ( --> Str ) {
      return self.get-xml-text;
    }

    #---------------------------------------------------------------------------
    #
  #  method conversion:<Str> ( --> Str ) {
  #    return self.get-xml-text;
  #  }

    #---------------------------------------------------------------------------
    # Expect filename without extension
    #
    method save ( Str :$filename is copy,
                  Str :$run-code,
                  XML::Document :$other-document
                ) {
      my $document = self.get-xml-text(:$other-document);
  #    my Str $document = self;

      my Hash $configuration = $!defaults;
      self.gather-configuration(
        $configuration,
        $!configuration,
        $!actions.config
      );

  #say $configuration<output><program>.perl;

      if $run-code.defined {
        my $cmd = $configuration<output><program>{$run-code};

        if $cmd.defined {

  #-----
  # Temporary solution for pipe to command
  #
  # If not defined or empty device name from config
  #
  if !?$filename {
    $filename = $configuration<output><filename>;
    my $fileext = $configuration<output><fileext>;

    $filename ~= ".$fileext";
  }

  # If not absolute prefix the path from the config
  #
  if $filename !~~ m@'/'@ {
    my $filepath = $configuration<output><filepath>;
    $filename = "$filepath/$filename" if $filepath;
  }

  $filename = [~] $filename, '___ ___';
  spurt( $filename, $document);
  #-----

          $cmd ~~ s:g/\n/ /;
          $cmd ~~ s:g/\s+/ /;
          $cmd ~~ s/^\s*\|//;
  #        my $program-io = IO::Pipe.to($cmd);
  #say "IO: $program-io";

          # No pipe to executable at the moment so take a different route...
          #
  #        spurt( '.-temp-file-to-store-command-.sh', "cat $filename | $cmd");
  say "Cmd: cat $filename | $cmd";
          shell("cat '$filename' | $cmd");
          unlink $filename;
        }

        else {
          $filename = $configuration<output><filename>;
          my $fileext = $configuration<output><fileext>;
          $filename ~= ".$fileext";

          say "Code '$run-code' to select command not found, Choosen to dump to $filename";
        }
      }

      else {
        if !$filename.defined {
          $filename = $configuration<output><filename>;
          my $fileext = $configuration<output><fileext>;

          $filename ~= ".$fileext";
        }

        my $filepath = $configuration<output><filepath>;
        mkdir $filepath unless $filepath.IO ~~ :e;

        if $filename !~~ m@'/'@ {
          $filename = "$filepath/$filename" if $filepath;
        }

        spurt( $filename, $document);
      }
    }

    #---------------------------------------------------------------------------
    #
    method get-xml-text ( :$other-document --> Str ) {

      # Get the top element name
      #
      my $root-element = ?$other-document
                           ?? $other-document.root.name
                           !! $!actions.get-document.root.name;
      $root-element ~~ s/^(<-[:]>+\:)//;

      my Str $document = '';

      # Get all configuration items in one hash, later settings overrides
      # previous Therefore defaults first, then from user config in roles then
      # the settings from the sxml file.
      #
      my Hash $configuration = $!defaults;
      self.gather-configuration( $configuration, $!configuration, $!actions.config);

      # If there is one, try to generate the xml
      #
      if ?$root-element {

        # Check if a http header must be shown
        #
        my Hash $http-header = $configuration<option><http-header>;

        if ? $http-header<show> {
          for $http-header.kv -> $k, $v {
            next if $k ~~ 'show';
            $document ~= "$k: $v\n";
          }
          $document ~= "\n";
        }

        # Check if xml prelude must be shown
        #
        my Hash $xml-prelude = $configuration<option><xml-prelude>;

        if ? $xml-prelude<show> {
          my $version = $xml-prelude<version>;
          my $encoding = $xml-prelude<encoding>;

          $document ~= "<?xml version=\"$version\"";
          $document ~= " encoding=\"$encoding\"?>\n";
        }

        # Check if doctype must be shown
        #
        my Hash $doc-type = $configuration<option><doctype>;

        if ? $doc-type<show> {
          my $definition = $doc-type<definition>;
          my $ws = $definition ?? ' ' !! '';
          $document ~= "<!DOCTYPE $root-element$ws$definition>\n";
        }

        $document ~= ?$other-document
                        ?? $other-document.root
                        !! $!actions.get-document.root;
      }

      return $document;
    }

    #---------------------------------------------------------------------------
    # Gather information from @hashes in the config $cfg. The config is
    # modified to containt all possible settings from the hashes. The $cfg
    # cannot be empty
    #
    method gather-configuration ( Hash $cfg, *@hashes --> Hash ) {
      for @hashes -> Hash $h {
        for $h.kv -> $k, $v {
          given $v {
            when Hash {
              if ?$cfg{$k} {
                self.gather-configuration( $cfg{$k}, $v);
              }

              else {
                $cfg{$k} = $v;
              }
            }

            default {
              $cfg{$k} = $v;
            }
          }
        }
      }

      return $cfg;
    }

    #---------------------------------------------------------------------------
    #
    multi method get-option ( Array $hashes!, Str $option! --> Any ) {
      for $hashes.list -> $h {
        if $h{$option}:exists {
          return $h{$option};
        }
      }

      return Any;
    }

    #---------------------------------------------------------------------------
    #
    multi method get-option ( Str :$section = '',
                              Str :$sub-section = '',
                              Str :$option = ''
                              --> Any
                            ) {
      my Array $hashes;
      for ( $!actions.config, $!configuration, $!defaults) -> $h {
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
}

#-------------------------------------------------------------------------------
#
multi sub prefix:<~>( Semi-xml::Sxml $x --> Str ) {
  return ~$x.get-xml-text;
}

