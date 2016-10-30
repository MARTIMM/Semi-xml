use v6.c;
use XML;
use SemiXML::Grammar;
use SemiXML::Actions;
use Config::DataLang::Refine;
use Terminal::ANSIColor;

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
    }

    #---------------------------------------------------------------------------
    method parse-file ( Str :$filename, Hash :$config --> ParseResult ) {

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
        }

        my $text = slurp($filename);
        $pr = self.parse( :content($text), :$config);
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

      # Check if modules needs to be instantiated in the config
      $!actions.process-config-for-modules;

      # Parse the content. Parse can be recursively called
      my Match $m = $!grammar.subparse( $content, :actions($!actions));

      # Throw an exception when there is a parsing failure
      if $m.to != $content.chars {
        my Str $before = $!actions.prematch();
        my Str $after = $!actions.postmatch();
        my Str $current = $content.substr( $!actions.from, $!actions.to - $!actions.from);

        $before ~ $current ~~ m:g/ (\n) /;
        my Int $nth-line = $/.elems + 1;

        $before ~~ s:g/ <-[\n]>* \n //;
        $after ~~ s:g/ \n <-[\n]>* //;

        die "Parse failure just after '$!actions.state()' at line $nth-line\n" ~
            $before ~ $current ~
            color('red') ~ "\x[23CF]$after" ~ color('reset');
      }

      $m;
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

      my Hash $configuration = $!actions.config;

      # Did not parse a file but content or filename not defined. In that case
      # take the name of the program and remove extention
      #
      if $configuration<output><filename>:!exists {
        my Str $fn = $*PROGRAM.basename;
        my Str $ext = $*PROGRAM.extension;
        $fn ~~ s/ '.' $ext //;
        $configuration<output><filename> = $fn;
      }

      # When the path is not defined, take the one of the program
      if $configuration<output><filepath>:!exists {
        my Str $fn = $*PROGRAM.abspath;
        my Str $bn = $*PROGRAM.basename;
        $fn ~~ s/ '/'? $bn //;
        $configuration<output><filepath> = $fn;
      }

      # Set the filename
      $filename = $configuration<output><filename> if not $filename.defined;
      $filename ~= "." ~ $configuration<output><fileext>;

      # If not absolute prefix the path from the config
      if $filename !~~ m/^ '/' / {
        my $filepath = $configuration<output><filepath>;
        $filename = "$filepath/$filename" if $filepath;
      }

      # Get the document text
      my $document = self.get-xml-text(:$other-document);

      # If a run code is defined, use that code as a key to find the program
      # to send the result to.
      #
      if $run-code.defined {
        my $cmd = $configuration<output><program>{$run-code};

        if $cmd.defined {

        # Drop the extention again. Let it be provided by the command
        my Str $ext = $filename.IO.extension;
        $filename ~~ s/ '.' $ext //;

          $cmd ~~ s/ '%of' /'$filename'/;
          say "Sent file to program: $cmd";
          my Proc $p = shell "$cmd 2> '{$run-code}-command.log'", :in;
          $p.in.print($document);
        }

        else {

          say "Code '$run-code' to select command not found, Choosen to dump to $filename";
        }
      }

      else {

        spurt( $filename, $document);
        say "Saved file in $filename";
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

    #-----------------------------------------------------------------------------
    sub append-element (
      XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
      --> XML::Node
    ) is export {

      my XML::Node $element;

      if ? $text {
        $element = SemiXML::Text.new(:$text);
      }

      else {
        $element = XML::Element.new( :$name, :attribs(%$attributes));
      }

      $parent.append($element);
      $element;
    }

    #-----------------------------------------------------------------------------
    sub insert-element (
      XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
      --> XML::Node
    ) is export {

      my XML::Node $element;

      if ? $text {
        $element = SemiXML::Text.new(:$text);
      }

      else {
        $element = XML::Element.new( :$name, :attribs(%$attributes));
      }

      $parent.insert($element);
      $element;
    }

    #-----------------------------------------------------------------------------
    sub before-element (
      XML::Element $node, Str $name = '', Hash $attributes = {}, Str :$text
      --> XML::Element
    ) is export {

      my XML::Node $element;

      if ? $text {
        $element = SemiXML::Text.new(:$text);
      }

      else {
        $element = XML::Element.new( :$name, :attribs(%$attributes));
      }

      $node.before($element);
      $element;
    }

    #-----------------------------------------------------------------------------
    sub after-element (
      XML::Element $node, Str $name = '', Hash $attributes = {}, Str :$text
      --> XML::Element
    ) is export {

      my XML::Node $element;

      if ? $text {
        $element = SemiXML::Text.new(:$text);
      }

      else {
        $element = XML::Element.new( :$name, :attribs(%$attributes));
      }

      $node.after($element);
      $element;
    }
  }
}

#-------------------------------------------------------------------------------
multi sub prefix:<~>( SemiXML::Sxml $x --> Str ) {
  return ~$x.get-xml-text;
}

