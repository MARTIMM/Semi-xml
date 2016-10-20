use v6.c;
use XML;
use SemiXML::Grammar;
use SemiXML::Actions;
use Config::DataLang::Refine;

#-------------------------------------------------------------------------------
#package SemiXML:ver<0.17.0>:auth<https://github.com/MARTIMM> {
package SemiXML:auth<https://github.com/MARTIMM> {

  subset ParseResult is export where $_ ~~ any(Match|Nil);

  class Sxml {

    our $debug = False;

    has SemiXML::Grammar $!grammar;
    has SemiXML::Actions $.actions;

    has Hash $.styles;
    has Config::DataLang::Refine $configuration;

    submethod BUILD ( ) {
      $!grammar .= new;
      $!actions .= new;

      my Str $rsrc-bn = %?RESOURCES<SemiXML.toml>.IO.basename;
      my Str $rsrc-p = %?RESOURCES<SemiXML.toml>.IO.abspath;
      my Str $rsrc-d = $rsrc-p;
      $rsrc-d ~~ s/ '/'? $rsrc-bn //;

      my Config::DataLang::Refine $c0 = self!load-config(
        :config-name($rsrc-bn),
        :locations([$rsrc-d])
      );

      my Hash $other-config = ? $c0 ?? $c0.config.clone !! {};
      $c0 = self!load-config( :config-name<SemiXML.toml>, :$other-config);

      $!actions.config = ? $c0 ?? $c0.config.clone !! $other-config;
      $!actions.process-config-for-modules;
    }

    #---------------------------------------------------------------------------
    method parse-file ( Str :$filename --> ParseResult ) {

      my ParseResult $pr;

      if $filename.IO ~~ :r {

        my Str $name-bn = $filename.IO.basename;
        my Str $name-p = $filename.IO.abspath;
        my Str $name-d = $name-p;
        $name-d ~~ s/ \/? $name-bn//;
        $name-bn ~~ s/ '.sxml' /.toml/;

        # Only assign if config is defined
        my Hash $other-config = $!actions.config.clone if ? $!actions.config;
        my Config::DataLang::Refine $c0 = self!load-config(
          :config-name($name-bn),
          :locations([$name-d]),
          :$other-config
        );

        # Set the config in the actions
        $!actions.config = ? $c0 ?? $c0.config.clone !! $other-config;

        # Did not parse a file but content
        if $!actions.config<output><filename>:!exists {
          my Str $fn = $filename.IO.basename;
          my $ext = $filename.IO.extension;
          $fn ~~ s/ '.' $ext //;
          $!actions.config<output><filename> = $fn;
        }

        if $!actions.config<output><filepath>:!exists {
          my Str $fn = $filename.IO.abspath;
          my Str $bn = $filename.IO.basename;
          $fn ~~ s/ '/'? $bn //;
          $!actions.config<output><filepath> = $fn;
          $!actions.process-config-for-modules;
        }

        my $text = slurp($filename);
        $pr = self.parse(:content($text));
        die "Parse failure" if $pr ~~ Nil;
      }

      else {
        die "Filename $filename not readable";
      }

      $pr;
    }

    #---------------------------------------------------------------------------
    method !load-config (
      Str :$config-name, Array :$locations = [], Hash :$other-config
      --> Config::DataLang::Refine
    ) {

      my Config::DataLang::Refine $c;
      try {
        if ?$other-config {
          $c .= new( :$config-name, :$locations, :$other-config);
        }

        else {
          $c .= new( :$config-name, :$locations);
        }

        CATCH {
#          .say;
          $c = Nil;
          default {
            # Ignore file not found exception
            if .message !~~ m/ :s Config file .* not found / {
              .rethrow;
            }
          }
        }

        $c;
      }
    }

    #---------------------------------------------------------------------------
    method parse ( Str :$content is copy, Hash :$config --> ParseResult ) {

      if $config.defined {
        my Config::DataLang::Refine $c;
        $!actions.config = $c.merge-hash( $!actions.config, $config);
      }

      # Remove comments, trailing and leading spaces
      $content ~~ s/^\s+//;
      $content ~~ s/\s+$//;

      # Get user introduced attribute information
      for self.^attributes -> $class-attr {
        given $class-attr.name {
          when '$!styles' {
            $!styles = $class-attr.get_value(self);
          }
        }
      }

      # Parse the content. Parse can be recursively called
      return $!grammar.parse( $content, :actions($!actions));
    }

    #---------------------------------------------------------------------------
    method root-element ( --> XML::Element ) {
      my $doc = $!actions.get-document;
      return ?$doc ?? $doc.root !! XML::Element;
    }

    #---------------------------------------------------------------------------
    method Str ( --> Str ) {
      return self.get-xml-text;
    }


    #---------------------------------------------------------------------------
    # Expect filename without extension
    method save ( Str :$filename is copy,
                  Str :$run-code,
                  XML::Document :$other-document
                ) {

      # Did not parse a file but content
      if $!actions.config<output><filename>:!exists {
        my Str $fn = $*PROGRAM.basename;
        my Str $ext = $*PROGRAM.extension;
        $fn ~~ s/ '.' $ext //;
        $!actions.config<output><filename> = $fn;
      }

      if $!actions.config<output><filepath>:!exists {
        my Str $fn = $*PROGRAM.abspath;
        my Str $bn = $*PROGRAM.basename;
        $fn ~~ s/ '/'? $bn //;
        $!actions.config<output><filepath> = $fn;
      }


      my $document = self.get-xml-text(:$other-document);

      my Hash $configuration = $!actions.config;

      if $run-code.defined {
        my $cmd = $configuration<output><program>{$run-code};

        if $cmd.defined {

          #-----
          # Temporary solution for pipe to command
          #
          # If not defined or empty device name from config
          #
          if not $filename.defined {
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
        if not $filename.defined {
          $filename = $configuration<output><filename>;
          my $fileext = $configuration<output><fileext>;

          $filename ~= ".$fileext";
        }

        if $filename !~~ m@'/'@ {
          my $filepath = $configuration<output><filepath>;
          $filename = "$filepath/$filename" if $filepath;
        }

        spurt( $filename, $document);
      }
    }

    #---------------------------------------------------------------------------
    method get-xml-text ( :$other-document --> Str ) {

      # Get the top element name
      #
      my $root-element;
      if ?$other-document {
        $root-element = $other-document.root.name;
      }

      else {
        my $doc = $!actions.get-document;
        $root-element = ?$doc ?? $doc.root.name !! Any;
say "X: ", $doc.perl;
      }
      return '' unless $root-element.defined;

      $root-element ~~ s/^(<-[:]>+\:)//;

      my Str $document = '';

      # Get all configuration items in one hash, later settings overrides
      # previous Therefore defaults first, then from user config in roles then
      # the settings from the sxml file.
      #
      my Hash $configuration = $!actions.config;

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
    multi method get-option ( Array $hashes, Str $option --> Any ) {
      for $hashes.list -> $h {
        if $h{$option}:exists {
          return $h{$option};
        }
      }

      return Any;
    }

    #---------------------------------------------------------------------------
    multi method get-option ( Str :$section = '',
                              Str :$sub-section = '',
                              Str :$option = ''
                              --> Any
                            ) {
      my Array $hashes;
      for ( $!actions.config) -> $h {
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

    #---------------------------------------------------------------------------
    # Used from plugins to find the PLACEHOLDER-ELEMENT tag in the given
    # parent node.
    #
    method find-placeholder ( XML::Element $parent --> XML::Element ) {

      my XML::Node $placeholder;
      for $parent.nodes -> $node {
        if $node ~~ XML::Element and $node.name eq 'PLACEHOLDER-ELEMENT' {
          $placeholder = $node;
          last;
        }
      }

      return $placeholder;
    }
  }
}

#-------------------------------------------------------------------------------
multi sub prefix:<~>( SemiXML::Sxml $x --> Str ) {
  return ~$x.get-xml-text;
}

