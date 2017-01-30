use v6.c;
use XML;
use SemiXML::Grammar;
use SemiXML::Actions;
use Config::DataLang::Refine;
use Terminal::ANSIColor;

#-------------------------------------------------------------------------------
package SemiXML:ver<0.26.4>:auth<https://github.com/MARTIMM> {

  subset ParseResult is export where $_ ~~ any(Match|Nil);

  class Sxml {

    our $debug = False;

    has SemiXML::Grammar $!grammar;
    has SemiXML::Actions $.actions handles <
      get-sxml-object get-current-filename
    >;

    has Hash $.styles;
    has Config::DataLang::Refine $configuration;

    submethod BUILD ( Str :$filename ) {
      $!grammar .= new;
      $!actions .= new(:sxml-obj(self));

      # Load the config file from resources. This is an sha encoded file when
      # installed, so this one will be the only one.
      my Config::DataLang::Refine $c0 = self!load-config(
        :config-name(%?RESOURCES<SemiXML.toml>.IO.abspath)
      );
#say "L: ", $locations.perl;
#say "C: $merge";
#say "--[dd]", '-' x 74;
#dd $c0.config;

      my Array $locations;
      my Hash $other-config = ? $c0 ?? $c0.config.clone !! {};
      # if filename is given, use its path also in its locations
      if ?$filename and $filename.IO ~~ :r {
        my Str $fn-bn = $filename.IO.basename;
        my Str $fn-p = $filename.IO.abspath;
        my Str $fn-d = $fn-p;
        $fn-d ~~ s/ '/'? $fn-bn //;
        $locations = [$fn-d];

        # load the default config file name from several locations
        $c0 = self!load-config(
          :config-name<SemiXML.toml>, :$other-config, :$locations, :merge
        );
#say "--[dd]", '-' x 74;
#dd $c0.config;

        # then load the sxml config file name from several locations
        $other-config = ? $c0 ?? $c0.config.clone !! {};
        $fn-p ~~ s/ $fn-d '/'? //;
        my $fn-e = $filename.IO.extension;
        $fn-p ~~ s/ $fn-e $/toml/;
        $c0 = self!load-config(
          :config-name($fn-p), :$other-config, :$locations, :merge
        );
      }
#say "--[dd]", '-' x 74;
#dd $c0.config;

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

#`{{
        # Only assign if config is defined
        my Hash $other-config = $!actions.config.clone if ? $!actions.config;
        my Config::DataLang::Refine $c0 = self!load-config(
          :config-name($name-bn),
          :locations([$name-d]),
          :$other-config
        );

        # Set the config in the actions
        $!actions.config = ? $c0 ?? $c0.config.clone !! $other-config;
}}
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
      Str :$config-name, Array :$locations = [], Hash :$other-config,
      Bool :$merge
      --> Config::DataLang::Refine
    ) {

      my Config::DataLang::Refine $c;
      try {

        if ?$other-config {
          $c .= new( :$config-name, :$locations, :$other-config, :$merge);
        }

        else {
say "$config-name, $locations, {$merge//'-'}";
          $c .= new( :$config-name, :$locations, :$merge);
        }

        CATCH {
#          .say;
          $c = Nil;
          default {
            # Ignore file not found exception
            if .message !~~ m/ :s Config files .* not found / {
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

        if $!actions.unleveled-brackets.elems {
          die [~] "Parse failure possible missing bracket at\n",
          map {"  line $_<line-begin>-$_<line-end>, tag $_<tag-name>, body number $_<body-count>\n"},
              @($!actions.unleveled-brackets);
        }

        if $!actions.mismatched-brackets.elems {
          die [~] "Parse failure possible mismatched bracket types at\n",
          map {"  line $_<line-begin>-$_<line-end>, tag $_<tag-name>, body number $_<body-count>\n"},
              @($!actions.mismatched-brackets);
        }

        if $after.chars {
          die "Parse failure just after '$!actions.state()' at line $nth-line\n" ~
              $before ~ $current ~
              color('red') ~ "\x[23CF]$after" ~ color('reset');
        }
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
      # take the name of the program and remove extension
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
        $fn ~~ s/ ('/'||\\)? $bn //;
        $configuration<output><filepath> = $fn;
      }

      # Set the filename
      $filename = $filename.IO.basename if $filename.defined;
      $filename = $configuration<output><filename> unless $filename.defined;

      # substitute extension
      my Str $ext = $filename.IO.extension;
      $filename ~~ s/ '.' $ext //;
      $filename ~= "." ~ ($configuration<output><fileext> // 'xml');

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
          $cmd ~~ s:g/ '%of' /'$filename'/;

          my Str $path = $configuration<output><filepath>;
          $cmd ~~ s:g/ '%op' /'$path'/;

          $ext = $configuration<output><fileext>;
          $cmd ~~ s:g/ '%oe' /'$ext'/;

          say "Sent file to program: $cmd";
          my Proc $p = shell "$cmd ", :in; #, :err;
          $p.in.print($document);
#`{{
say "P0: ", $p.perl;

          # wait for errors if any
          my @lines = $p.err.lines;
say "P1: ", $p.perl;

          say "\n---[Error output]", '-' x 63 if @lines.elems;
          .say for @lines;
          say "---[Finish error]", '-' x 63 if @lines.elems;

          # wait for promise to finish
          my Promise $send-it .= start( { $p.in.print($document); say 'done'; });
          $send-it.result;
}}
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
      if ?$root-element {

        # Check if a http header must be shown
        my Hash $http-header = $configuration<option><http-header> // {};

        if ? $http-header<show> {
          for $http-header.kv -> $k, $v {
            next if $k ~~ 'show';
            $document ~= "$k: $v\n";
          }
          $document ~= "\n";
        }

        # Check if xml prelude must be shown
        my Hash $xml-prelude = $configuration<option><xml-prelude> // {};

        if ? $xml-prelude<show> {
          my $version = $xml-prelude<version> // '1.0';
          my $encoding = $xml-prelude<encoding> // 'utf-8';

          $document ~= "<?xml version=\"$version\"";
          $document ~= " encoding=\"$encoding\"?>\n";
        }

        # Check if doctype must be shown
        my Hash $doc-type = $configuration<option><doctype> // {};

        if ? $doc-type<show> {
          my Hash $entities = $doc-type<entities> // {};
          my Str $start = ?$entities ?? " [\n" !! '';
          my Str $end = ?$entities ?? "]>\n" !! ">\n";
          $document ~= "<!DOCTYPE $root-element$start";
          for $entities.kv -> $k, $v {
            $document ~= "<!ENTITY $k \"$v\">\n";
          }
          $document ~= "$end\n";
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
      --> XML::Node
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
      --> XML::Node
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

