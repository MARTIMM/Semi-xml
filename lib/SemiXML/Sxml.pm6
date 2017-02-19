use v6.c;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<https://github.com/MARTIMM>;

use SemiXML::Grammar;
use SemiXML::Actions;
use Config::DataLang::Refine;
use Terminal::ANSIColor;

use XML;

subset ParseResult is export where $_ ~~ any(Match|Nil);

#-------------------------------------------------------------------------------
class Sxml {

  has SemiXML::Grammar $!grammar;
  has SemiXML::Actions $.actions handles < get-sxml-object >;

  has Hash $.styles;
  has Config::DataLang::Refine $!configuration;

  has Bool $!trace;
  has Bool $!merge;
  
  has Str $!filename;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$filename, Hash :$config, :$!trace = False, :$!merge = False ) {
    $!grammar .= new;
    $!actions .= new(:sxml-obj(self));
    
    self!prepare-config( :$!filename, :$config, :$!trace, :$!merge);
  }

  #-----------------------------------------------------------------------------
  method !prepare-config (
    Str :$!filename, Hash :$config, :$!trace = False, :$!merge = False
  ) {


#`{{
my $R = Distribution::Resources.new(:repo<SemiXML::Sxml>, :dist-id(''));
note "\n My C: ", $R<SemiXML.toml>;
note "\n My R: ", $R.perl;

$R = Distribution::Resources.new(:repo<file#/home/marcel/Languages/Perl6/Projects/Semi-xml>, :dist-id(''));
note "\n My C: ", $R<SemiXML.toml>;
note "\n My R: ", $R.perl;

$R = Distribution::Resources.new(:repo<Pod::Render>, :dist-id(''));
note "\n My C: ", $R<pod6.css>;
note "\n My R: ", $R.perl;

$R = Distribution::Resources.new(:repo<file#/home/marcel/Languages/Perl6/Projects/Semi-xml>, :dist-id(''));
note "\n My C: ", $R<SemiXML.toml>;
note "\n My R: ", $R.perl;

$R = Distribution::Resources.new(:repo<file#/home/marcel/Languages/Perl6/Projects/Semi-xml/lib>, :dist-id(''));
note "\n My C: ", $R<SemiXML.toml>;
note "\n My R: ", $R.perl;

}}

    # load the config file from resources first

# There is bug locally to this package. Resources get wrong path when using
# local distribution. However, strange as it is, not on Travis!
note "\nR: ", %?RESOURCES.perl;
note "\nC: ", %?RESOURCES<SemiXML.toml>;

my Str $rp = %?RESOURCES<SemiXML.toml>.Str;
if ! %?RESOURCES.dist-id and %?RESOURCES.repo !~~ m/ '/lib' $/ {
  $rp = "/home/marcel/Languages/Perl6/Projects/Semi-xml/resources/SemiXML.toml"
}
$!configuration = self!load-config(:config-name($rp.IO.abspath));

#    $!configuration = self!load-config(
#      :config-name(%?RESOURCES<SemiXML.toml>.Str)
#    );

    my Array $locations;
    my Hash $other-config =
       ? $!configuration ?? $!configuration.config.clone !! {};

    # if filename is given, use its path also in its locations
    if ?$!filename and $!filename.IO ~~ :r {
      my Str $fn-bn = $!filename.IO.basename;
      my Str $fn-p = $!filename.IO.abspath;
      my Str $fn-d = $fn-p;
      $fn-d ~~ s/ '/'? $fn-bn //;
      $locations = [$fn-d];

      # load the default config file name from several locations
      $!configuration = self!load-config(
        :config-name<SemiXML.toml>, :$other-config, :$locations, :merge
      );

      # then load the sxml config file name from several locations
      $other-config = ? $!configuration ?? $!configuration.config.clone !! {};

      $fn-p ~~ s/ $fn-d '/'? //;
      my $fn-e = $!filename.IO.extension;
      $fn-p ~~ s/ $fn-e $/toml/;
      $!configuration = self!load-config(
        :config-name($fn-p), :$other-config, :$locations, :merge
      );
    }

note "\nConfiguration: ", $!configuration.perl;
    $!actions.config = $!configuration.config;
  }

  #-----------------------------------------------------------------------------
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

  #-----------------------------------------------------------------------------
  method !load-config (
    Str :$config-name, Array :$locations = [], Hash :$other-config,
    Bool :$m = False
    --> Config::DataLang::Refine
  ) {

    my Bool $merge = $!merge ?| $m;
    my Config::DataLang::Refine $c;
    try {

      if ?$other-config {
        $c .= new(
          :$config-name, :$locations, :$other-config, :$merge, :$!trace
        );
      }

      else {
        $c .= new( :$config-name, :$locations, :$merge, :$!trace);
      }

      CATCH {
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

  #-----------------------------------------------------------------------------
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

  #-----------------------------------------------------------------------------
  method root-element ( --> XML::Element ) {
    my $doc = $!actions.get-document;
    return ?$doc ?? $doc.root !! XML::Element;
  }

  #-----------------------------------------------------------------------------
  method Str ( --> Str ) {
    return self.get-xml-text;
  }

  #-----------------------------------------------------------------------------
  # Expect filename without extension
  method save ( Str :$filename is copy,
                Str :$run-code,
                XML::Document :$other-document
              ) {

    my Hash $config = $!actions.config;

    # Did not parse a file but content or filename not defined. In that case
    # take the name of the program and remove extension
    #
    if $config<output><filename>:!exists {
      my Str $fn = $*PROGRAM.basename;
      my Str $ext = $*PROGRAM.extension;
      $fn ~~ s/ '.' $ext //;
      $config<output><filename> = $fn;
    }

    # When the path is not defined, take the one of the program
    if $config<output><filepath>:!exists {
      my Str $fn = $*PROGRAM.abspath;
      my Str $bn = $*PROGRAM.basename;
      $fn ~~ s/ ('/'||\\)? $bn //;
      $config<output><filepath> = $fn;
    }

    # Set the filename
    $filename = $filename.IO.basename if $filename.defined;
    $filename = $config<output><filename> unless $filename.defined;

    # substitute extension
    my Str $ext = $filename.IO.extension;
    $filename ~~ s/ '.' $ext //;
    $filename ~= "." ~ ($config<output><fileext> // 'xml');

    # If not absolute prefix the path from the config
    if $filename !~~ m/^ '/' / {
      my $filepath = $config<output><filepath>;
      $filename = "$filepath/$filename" if $filepath;
    }

    # Get the document text
    my $document = self.get-xml-text(:$other-document);

    # If a run code is defined, use that code as a key to find the program
    # to send the result to.
    #
    if $run-code.defined {
      my $cmd = $config<output><program>{$run-code};

      if $cmd.defined {

        # Drop the extention again. Let it be provided by the command
        my Str $ext = $filename.IO.extension;
        $filename ~~ s/ '.' $ext //;
        $filename = $filename.IO.basename;
        $cmd ~~ s:g/ '%of' /'$filename'/;

        my Str $path = $config<output><filepath>;
        $cmd ~~ s:g/ '%op' /'$path'/;

        $ext = $config<output><fileext>;
        $cmd ~~ s:g/ '%oe' /'$ext'/;

        say "Sent file to program: $cmd";
        my Proc $p = shell "$cmd ", :in;#, :err;
#`{{
        # wait for promise to finish
        my Promise $send-it .= start( {
            my @lines = $p.err.lines;
            $p.err.close;
#              note 'done';
            note "\n---[Output]", '-' x 63 if @lines.elems;
            .note for @lines;
            note "---[Finish output]", '-' x 63 if @lines.elems;
          }
        );

        sleep 0.5;
}}
        $p.in.print($document);
        $p.in.close;

#          $send-it.result;
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

  #-----------------------------------------------------------------------------
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
    my Hash $config = $!actions.config;

    # If there is one, try to generate the xml
    if ?$root-element {

      # Check if a http header must be shown
      my Hash $http-header = $config<option><http-header> // {};

      if ? $http-header<show> {
        for $http-header.kv -> $k, $v {
          next if $k ~~ 'show';
          $document ~= "$k: $v\n";
        }
        $document ~= "\n";
      }

      # Check if xml prelude must be shown
      my Hash $xml-prelude = $config<option><xml-prelude> // {};

      if ? $xml-prelude<show> {
        my $version = $xml-prelude<version> // '1.0';
        my $encoding = $xml-prelude<encoding> // 'utf-8';
        my $standalone = $xml-prelude<standalone>;

        $document ~= '<?xml version="' ~ $version ~ '"';
        $document ~= ' encoding="' ~ $encoding ~ '"';
        $document ~= ' standalone="' ~ $standalone ~ '"' if $standalone;
        $document ~= "?>\n";
      }

      # Check if doctype must be shown
      my Hash $doc-type = $config<option><doctype> // {};

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

  #-----------------------------------------------------------------------------
  multi method get-option ( Array $hashes, Str $option --> Any ) {
    for $hashes.list -> $h {
      if $h{$option}:exists {
        return $h{$option};
      }
    }

    return Any;
  }


  multi method get-option (
    Str :$section = '', Str :$sub-section = '', Str :$option = ''
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
  method get-current-filename ( --> Str ) {

    return [~] $!configuration.config<output><filepath>,
               '/', $!configuration.config<output><filename>;
  }

  #-----------------------------------------------------------------------------
  multi sub save-xml (
    Str:D :$filename, XML::Element:D :$document!,
    Hash :$config = {}, Bool :$formatted = False,
  ) is export {
    my XML::Document $root .= new($document);
    save-xml( :$filename, :document($root), :$config, :$formatted);
  }

  multi sub save-xml (
    Str:D :$filename, XML::Document:D :$document!,
    Hash :$config = {}, Bool :$formatted = False
  ) is export {

    # Get the document text
    my Str $text;

    # Get the top element name
    my Str $root-element = $document.root.name;
#      $root-element ~~ s/^(<-[:]>+\:)//;


    # If there is one, try to generate the xml
    if ?$root-element {

      # Check if a http header must be shown
      my Hash $http-header = $config<option><http-header> // {};

      if ? $http-header<show> {
        for $http-header.kv -> $k, $v {
          next if $k ~~ 'show';
          $text ~= "$k: $v\n";
        }
        $text ~= "\n";
      }

      # Check if xml prelude must be shown
      my Hash $xml-prelude = $config<option><xml-prelude> // {};

      if ? $xml-prelude<show> {
        my $version = $xml-prelude<version> // '1.0';
        my $encoding = $xml-prelude<encoding> // 'utf-8';
        my $standalone = $xml-prelude<standalone>;

        $text ~= '<?xml version="' ~ $version ~ '"';
        $text ~= ' encoding="' ~ $encoding ~ '"';
        $text ~= ' standalone="' ~ $standalone ~ '"' if $standalone;
        $text ~= "?>\n";
      }

      # Check if doctype must be shown
      my Hash $doc-type = $config<option><doctype> // {};

      if ? $doc-type<show> {
        my Hash $entities = $doc-type<entities> // {};
        my Str $start = ?$entities ?? " [\n" !! '';
        my Str $end = ?$entities ?? "]>\n" !! ">\n";
        $text ~= "<!DOCTYPE $root-element$start";
        for $entities.kv -> $k, $v {
          $text ~= "<!ENTITY $k \"$v\">\n";
        }
        $text ~= "$end\n";
      }

      $text ~= ? $document ?? $document.root !! '';
    }

    # Save the text to file
    if $formatted {
      my Proc $p = shell "xmllint -format - > $filename", :in;
      $p.in.say($text);
      $p.in.close;
    }

    else {
      spurt( $filename, $text);
    }
  }

  #-----------------------------------------------------------------------------
  sub append-element (
    XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
    --> XML::Node
  ) is export {

    my XML::Node $text-element = SemiXML::Text.new(:$text) if ? $text;
    my XML::Node $element =
       XML::Element.new( :$name, :attribs(%$attributes)) if ? $name;

    if ? $name and ? $text {
      $element.append($text-element);
    }

    elsif ? $text {
      $element = $text-element;
    }

    # else $name -> no change to $element. No name and no text is an error.

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

#-------------------------------------------------------------------------------
multi sub prefix:<~>( SemiXML::Sxml $x --> Str ) is export {
  return ~$x.get-xml-text;
}

