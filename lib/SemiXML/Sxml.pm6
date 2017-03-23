use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<https://github.com/MARTIMM>;

use SemiXML::Grammar;
use SemiXML::Actions;
use SemiXML::Text;
use Config::DataLang::Refine;
use Terminal::ANSIColor;

use XML;

subset ParseResult is export where $_ ~~ any(Match|Nil);

#-------------------------------------------------------------------------------
class Sxml {

  has SemiXML::Grammar $!grammar;
  has SemiXML::Actions $!actions;

  has Config::DataLang::Refine $!configuration;

  enum RKeys <<:IN(0) :OUT(1)>>;
  has Array $!refine;
  has Array $!refine-tables;
  has Hash $!refined-config;

  has Hash $!objects = {};

  has Str $!filename;
  has Str $!basename;

  has Bool $!drop-cfg-filename;
  has Hash $!user-config;
  has Bool $!trace;
  has Bool $!merge;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Array :$!refine = [], :$!trace = False, :$!merge = False ) {

    $!grammar .= new;
    $!actions .= new(:sxml-obj(self));

    # Make sure that in and out keys are defined with defaults
    $!refine[0] = 'xml' unless ?$!refine[IN];
    $!refine[1] = 'xml' unless ?$!refine[OUT];

    # Initialize the refined config tables
    $!refine-tables = [<C D E H ML R S>];
    $!refined-config = %(@$!refine-tables Z=> ( {} xx $!refine-tables.elems ));
  }

  #-----------------------------------------------------------------------------
  multi method parse ( Str:D :$!filename!, Hash :$config --> ParseResult ) {

    my ParseResult $pr;

    if $!filename.IO ~~ :r {
      my $text = slurp($!filename);
      $pr = self.parse( :content($text), :$config, :!drop-cfg-filename);
      die "Parse failure" if $pr ~~ Nil;
    }

    else {
      die "Filename $!filename not readable";
    }

    $pr;
  }

  #-----------------------------------------------------------------------------
  multi method parse (
    Str:D :$content! is copy, Hash :$config, Bool :$!drop-cfg-filename = True
    --> ParseResult
  ) {

    $!user-config = $config;
    $!filename = Str if $!drop-cfg-filename;
    self!prepare-config;

    # Parse the content. Parse can be recursively called
    my Match $m = $!grammar.subparse( $content, :actions($!actions));
note "Match: $m.from(), $m.to(), $m.chars()\n", ~$m;

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
  # Save file to filename or devise filename from config
  method save (
    Str :$filename is copy, Str :$run-code, XML::Document :$other-document
  ) {

    # set the filename if needed
    if ?$filename {
      $filename = $filename.IO.basename;
    }

    else {
      $filename = $!refined-config<S><filename>;
    }

    # modify extension
    my Str $ext = $filename.IO.extension;
    $filename ~~ s/ '.' $ext //;
    $filename ~= "." ~ $!refined-config<S><fileext>;

    # if not absolute prefix the path from the config
    if $filename !~~ m/^ '/' / {
      my $filepath = $!refined-config<S><filepath>;
      $filename = "$filepath/$filename" if $filepath;
    }

    # Get the document text
    my $document = self.get-xml-text(:$other-document);

    # If a run code is defined, use that code as a key to find the program
    # to send the result to.
    #
    if $run-code.defined {
      my $cmd = $!refined-config<R><program>{$run-code};

      if $cmd.defined {

        # Drop the extension again. Let it be provided by the command
        my Str $ext = $filename.IO.extension;
        $filename ~~ s/ '.' $ext //;
        $filename = $filename.IO.basename;
        $cmd ~~ s:g/ '%of' /'$filename'/;

        my Str $path = $!refined-config<S><filepath>;
        $cmd ~~ s:g/ '%op' /'$path'/;

        $ext = $!refined-config<S><fileext>;
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

        note "Code '$run-code' to select command not found, Choosen to dump to $filename";
      }
    }

    else {

      spurt( $filename, $document);
      note "Saved file in $filename";
    }
  }

  #-----------------------------------------------------------------------------
  method get-xml-text ( :$other-document --> Str ) {

    # Get the top element name
    my $root-element;
    if ?$other-document {
      $root-element = $other-document.root.name;
    }

    else {
      my $doc = $!actions.get-document;
      $root-element = ?$doc ?? $doc.root.name !! Any;
    }
    return '' unless $root-element.defined;

    # remove namespace part from root element
    $root-element ~~ s/^(<-[:]>+\:)//;

    my Str $document = '';

    # If there is a root element, try to generate the xml
    if ?$root-element {

      # Check if a http header must be shown
      if $!refined-config<C><header-show> and ? $!refined-config<H> {
        for $!refined-config<H>.kv -> $k, $v {
          $document ~= "$k: $v\n";
        }
        $document ~= "\n";
      }

      # Check if xml prelude must be shown
      if ? $!refined-config<C><xml-show> {
        my $version = $!refined-config<C><xml-version> // '1.0';
        my $encoding = $!refined-config<C><xml-encoding> // 'utf-8';
        my $standalone = $!refined-config<C><xml-standalone>;

        $document ~= '<?xml version="' ~ $version ~ '"';
        $document ~= ' encoding="' ~ $encoding ~ '"';
        $document ~= ' standalone="' ~ $standalone ~ '"' if $standalone;
        $document ~= "?>\n";
      }

      # Check if doctype must be shown
      if ? $!refined-config<C><doctype-show> {
        my Hash $entities = $!refined-config<E> // {};
        my Str $start = ?$entities ?? " [\n" !! '';
        my Str $end = ?$entities ?? "]>" !! ">";
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
  multi method get-config ( Str:D :$table, Str:D :$key --> Any ) {

    return (
      $!refined-config{$table}:exists
        ?? $!refined-config{$table}{$key}
        !! Any
    );
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
#TODO check if still needed
  method get-current-filename ( --> Str ) {

    my Hash $C = $!refined-config<C>;
    return "$C<filepath>/$C<filename>.$C<fileext>";
  }

  #-----------------------------------------------------------------------------
  method !prepare-config ( ) {

    # 1) Cleanup old configs
    $!configuration = Config::DataLang::Refine;

    # 2) load the SemiXML.toml from resources directory

# There is a bug locally to this package. Resources get wrong path when using
# local distribution. However, strange as it is, not on Travis! This is Caused
# by wrong? use of PERL6LIB env variable.
#note "\nR: ", %?RESOURCES.perl;
#note "\nC: ", %?RESOURCES<SemiXML.toml>;

#my Str $rp = %?RESOURCES<SemiXML.toml>.Str;
#if ! %?RESOURCES.dist-id and %?RESOURCES.repo !~~ m/ '/lib' $/ {
#  $rp = "/home/marcel/Languages/Perl6/Projects/Semi-xml/resources/SemiXML.toml"
#}
# pick only one config file. Will always be there.
#self!load-config( :config-name($rp.IO.abspath), :!merge);

    self!load-config( :config-name(%?RESOURCES<SemiXML.toml>.Str), :!merge);

    # 3) if filename is given, use its path also
    my Array $locations;
    my Str $fpath;
    my Str $fdir;
    my Str $fext;
    if ?$!filename and $!filename.IO ~~ :r {

      my $bname = $!basename = $!filename.IO.basename;
      $fpath = $!filename.IO.abspath;
      $fdir = $fpath;
      $fext = $*PROGRAM.extension;
      $!basename ~~ s/ '.' $fext //;
      $fdir ~~ s/ '/'? $bname //;
      $locations = [$fdir];

      # 3a) to load SemiXML.TOML from the files location, current dir
      #     (also hidden), and in $HOME. merge is controlled by user.
      self!load-config( :config-name<SemiXML.toml>, :$locations, :merge);

      # 3b) same as in 3a but use the filename now.
      $fext = $!filename.IO.extension;
      $!basename ~~ s/ $fext $/toml/;
      self!load-config( :config-name($!basename), :$locations, :merge);
    }

    # 4) if filename is not given, the configuration is searched using the
    # program name
    else {

      # in case it was set but not found/readable
      $!filename = Str;

      self!load-config(:merge);
    }

    # 5) merge any user configuration in it
    $!configuration.config =
      $!configuration.merge-hash($!user-config) if ?$!user-config;


    # set filename and path if not set, extension is set in default config
    my Hash $c := $!configuration.config;
    $c<S> = {} unless $c<S>:exists;

    if $c<S><filename>:!exists {
      if ?$!basename {
        # lop off the extension from the above devised config name
        $!basename ~~ s/ '.toml' $// if ?$!basename;
        $c<S><filename> = $!basename;
      }

      else {
        $!basename = $*PROGRAM.basename;
        $fext = $*PROGRAM.extension;
        $!basename ~~ s/ '.' $fext //;
        $c<S><filename> = $!basename;
      }
    }

    if $c<S><filepath>:!exists {
      if ?$fdir {
        $c<S><filepath> = $fdir;
      }

      else {
        $fdir = $*PROGRAM.abspath;
        my $bname = $!basename = $*PROGRAM.basename;
        $fdir ~~ s/ '/'? $bname //;
        $c<S><filepath> = $fdir;
      }
    }

    note "\nComplete configuration: ", $!configuration.perl,
         "\nRefined configuration tables" if $!trace;

    # Fill the special purpose tables with the refined searches in the config
    for @$!refine-tables {
      when any(<C E>) {
        my $table = $_;
        $!refined-config{$table} =
          $!configuration.refine(|( $table, $!refine[OUT], $!basename));

        note "Table $table: out=", $!refine[OUT], ', basename=', $!basename,
        ";\n", $!configuration.perl(:h($!refined-config{$table})) if $!trace;
      }

      when any(<D H ML R>) {
        my $table = $_;
        $!refined-config{$table} =
          $!configuration.refine(|( $table, $!refine[IN], $!basename));

        note "Table $table: in=", $!refine[IN], ', basename=', $!basename,
        ";\n", $!configuration.perl(:h($!refined-config{$table})) if $!trace;
      }

      when any(<S>) {
        my $table = $_;
        $!refined-config{$table} =
          $!configuration.refine(|( $table, $!basename));

        note "Table $table: basename=", $!basename,
        ";\n", $!configuration.perl(:h($!refined-config{$table})) if $!trace;
      }
    }

    # instantiate modules specified in the configuration
    self!process-modules;
  }

  #-----------------------------------------------------------------------------
  # Get modulenames and library paths. Format of an entry in table ML is
  # mod-key => 'mod-name[;lib-path]'
  method !process-modules ( ) {

    # no entries, no work
    return unless ? $!refined-config<ML>;

    my Hash $lib = {};
    my Hash $mod = {};
    for $!refined-config<ML>.keys -> $modkey {
      next unless ? $!refined-config<ML>{$modkey};

      ( my $m, my $l) = $!refined-config<ML>{$modkey}.split(';');
      $lib{$modkey} = $l if $l;
      $mod{$modkey} = $m;
    }

    # cleanup old objects
    for $!objects.keys -> $k {
      undefine $!objects{$k};
      $!objects{$k}:delete;
    }

    # load and instantiate
    for $mod.kv -> $key, $value {
      if $!objects{$key}:!exists {
        if $lib{$key}:exists {

#TODO test for duplicate paths
          my $repository = CompUnit::Repository::FileSystem.new(
            :prefix($lib{$key})
          );
          CompUnit::RepositoryRegistry.use-repository($repository);
        }

        require ::($value);
        my $obj = ::($value).new;
        $!objects{$key} = $obj;
      }
    }

    # Place in actions object.
    $!actions.objects = $!objects;
  }

  #-----------------------------------------------------------------------------
  method get-sxml-object ( Str $class-name ) {

    my $object;
    for $!objects.keys -> $ok {
      if $!objects{$ok}.^name eq $class-name {
        $object = $!objects{$ok};
        last;
      }
    }

    $object;
  }

  #-----------------------------------------------------------------------------
  method !load-config (
    Str :$config-name, Array :$locations = [], Bool :$merge is copy
  ) {

    $merge = $!merge ?& $merge;

    try {

      # $!configuration is always undefined the first time.
      if ?$!configuration {
        $!configuration .= new(
          :$config-name, :$locations, :other-config($!configuration.config),
          :$merge, :$!trace
        );
      }

      else {
        $!configuration .= new( :$config-name, :$locations, :$merge, :$!trace);
      }

      CATCH {
        default {
          # Ignore file not found exception
          if .message !~~ m/ :s Config files .* not found / {
            .rethrow;
          }
        }
      }
    }
  }

#`{{
  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
#TODO $config should come indirectly from $!refined-config
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

  #-----------------------------------------------------------------------------
  sub std-attrs (
    XML::Element $node, Hash $attributes
  ) is export {

    return unless ?$attributes;

    for $attributes.keys {
      when /'class'|'style'|'id'/ {
        $node.set( $_, $attributes{$_});
        $attributes{$_}:delete;
      }
    }
  }
}}
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
multi sub prefix:<~>( SemiXML::Sxml $x --> Str ) is export {
  return $x.get-xml-text;
}
