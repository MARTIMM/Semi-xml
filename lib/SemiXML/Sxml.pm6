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

  has Bool $!drop-cfg-filename;
  has Hash $!user-config;
  has Bool $!trace = False;
  has Bool $!merge;

  # structure to check for dependencies
  my Hash $processed-dependencies = {};

  #-----------------------------------------------------------------------------
  submethod BUILD ( Array :$!refine = [], :$!merge = False ) {

    $!grammar .= new;
    $!actions .= new(:sxml-obj(self));

    # Make sure that in and out keys are defined with defaults
    $!refine[IN] = 'xml' unless ?$!refine[IN];
    $!refine[OUT] = 'xml' unless ?$!refine[OUT];

    # Initialize the refined config tables
    $!refine-tables = [<C D E F H ML R S T X>];
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
      note "Filename $!filename not readable";
      exit(1);
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

    # Prepare config and process dependencies. If result is newer than source
    # prepare returns False to note that further work is not needed.
    # Generate a proper Match object to return.
    return Nil unless self!prepare-config;

    # Parse the content. Parse can be recursively called
    $SemiXML::Grammar::trace = ($!trace and $!refined-config<T><parse>);
    my Match $m = $!grammar.subparse( $content, :actions($!actions));

    # Throw an exception when there is a parsing failure
    my $last-bracket-index = $content.rindex(']') // $content.chars;
    if $!trace and $!refined-config<T><parse-result> {
      my $mtrace = ~$m;
      $mtrace .= substr( 0, 200);
      $mtrace ~= " ... \n";
      note "\nMatch: $m.from(), $m.to(), $last-bracket-index\n$mtrace";
    }
#    if $m.to != $last-bracket-index {
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
  # Save file using config
  method save ( ) {

    # Get the document text
    my $document = self.get-xml-text;

    # If a run code is defined, use that code as a key to find the program
    # to send the result to. If R-table entry is an Array, take the first
    # element. The second element is a result filename to check for modification
    # date. Check is done before parsing to see if paqrsing is needed.
    my $cmd;
    if $!refined-config<R>{$!refine[OUT]} ~~ Array {
      $cmd = $!refined-config<R>{$!refine[OUT]}[0];
    }

    else {
      $cmd = $!refined-config<R>{$!refine[OUT]};
    }

    # command is defined and non-empty
    if ?$cmd {

      $cmd = self!process-cmd-str($cmd);

      say "Send file to program: $cmd"
        if $!trace and $!refined-config<T><file-handling>;

      my Proc $p = shell "$cmd", :in;
      $p.in.print($document);
      $p.in.close;
    }

    else {

      my $filename = self!process-cmd-str("%op/%of.%oe");

      spurt( $filename, $document);
      note "Saved file in $filename"
        if $!trace and $!refined-config<T><file-handling>;
    }
  }

  #-----------------------------------------------------------------------------
  method Str ( --> Str ) {
    return self.get-xml-text;
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
        my $version = $!refined-config<X><xml-version> // '1.0';
        my $encoding = $!refined-config<X><xml-encoding> // 'utf-8';
        my $standalone = $!refined-config<X><xml-standalone>;

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
#TODO check if still needed
  method get-current-filename ( --> Str ) {

    my Hash $C = $!refined-config<C>;
    if ?$C<filepath> {
      "$C<rootpath>/$C<filepath>/$C<filename>.$C<fileext>";
    }

    else {
     "$C<rootpath>/$C<filename>.$C<fileext>";
    }
  }

  #-----------------------------------------------------------------------------
  method !process-cmd-str( Str $cmd-string --> Str ) {

    my $cmd = $cmd-string;

    # Bind to S table
    my Hash $S := $!refined-config<S>;

    # filename is basename + extension
#    my Str $filename = $S<filename> ~ '.' ~ $S<fileext>;

    $cmd ~~ s:g/ '%of' /$S<filename>/;

    my Str $path;
    if ?$S<filepath> {
      $path = $S<rootpath> ~ '/' ~ $S<filepath>;
    }

    else {
      $path = $S<rootpath>;
    }

    $cmd ~~ s:g/ '%op' /$path/;

#    my Str $ext = $S<fileext>;
    $cmd ~~ s:g/ '%oe' /$S<fileext>/;

    $cmd;
  }

  #-----------------------------------------------------------------------------
  method !prepare-config ( --> Bool ) {

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
#self!load-config( :config-name($rp.IO.absolute), :!merge);

    self!load-config( :config-name(%?RESOURCES<SemiXML.toml>.Str), :!merge);

    # 3) if filename is given, use its path also
    my Array $locations;
    my Str $fpath;
    my Str $fdir;
    my Str $fext;
    my Str $basename;

    if ?$!filename and $!filename.IO ~~ :r {

      $basename = $!filename.IO.basename;
      $fpath = $!filename.IO.absolute;
      $fdir = $fpath;
      $fdir ~~ s/ '/'? $basename //;
      $locations = [$fdir];
#      $fext = $*PROGRAM.extension;

      # 3a) to load SemiXML.TOML from the files location, current dir
      #     (also hidden), and in $HOME. merge is controlled by user.
      self!load-config( :config-name<SemiXML.toml>, :$locations, :merge);

      # 3b) same as in 3a but use the filename now.
      $fext = $!filename.IO.extension;
      $basename ~~ s/ $fext $/toml/;
      self!load-config( :config-name($basename), :$locations, :merge);
    }

    # 4) if filename is not given, the configuration is searched using the
    # program name
    else {

      # in case it was set by previous parse actions but not found or readable
      $!filename = Str;

      self!load-config(:merge);
    }

    # 5) merge any user configuration in it
    $!configuration.config =
      $!configuration.merge-hash($!user-config) if ?$!user-config;

    # $c is bound to the config in the configuration object.
    my Hash $c := $!configuration.config;

    # Do we need to show things
    $!trace = $c<C><tracing>;

    # set filename, path etc. if not set, extension is set in default config.
    $c<S> = {} unless $c<S>:exists;
    if $c<S><filename>:!exists {
      # take filename of sxml source
      if ?$basename {
        # lop off the extension from the above devised config name
        $basename ~~ s/ '.toml' $// if ?$basename;
        $c<S><filename> = $basename;
      }

      else {
        # take filename of program
        $basename = $*PROGRAM.basename;
        $fext = $*PROGRAM.extension;
        $basename ~~ s/ '.' $fext //;
        $c<S><filename> = $basename;
      }
    }

    if $c<S><rootpath>:!exists {
      if ?$fdir {
        $c<S><rootpath> = $fdir;
      }

      else {
        $fdir = $*PROGRAM.absolute;
        my $basename = $*PROGRAM.basename;
        $fdir ~~ s/ '/'? $basename //;
        $c<S><rootpath> = $fdir;
      }
    }

    if $c<S><filepath>:!exists {
      $c<S><filepath> = '';
    }

    # Fill the special purpose tables with the refined searches in the config
    for @$!refine-tables {
      # document control
      when any(<D E F ML R>) {
        my $table = $_;
        $!refined-config{$table} =
          $!configuration.refine(|( $table, $!refine[IN], $basename));

#        note "Table $table: in=", $!refine[IN], ', basename=', $basename,
#        ";\n", $!configuration.perl(:h($!refined-config{$table})) if $!trace;
      }

      # output control
      when any(<C H S X>) {
        my $table = $_;
        $!refined-config{$table} =
        $!configuration.refine(|( $table, $!refine[OUT], $basename));

#        note "Table $table: out=", $!refine[OUT], ', basename=', $basename,
#        ";\n", $!configuration.perl(:h($!refined-config{$table})) if $!trace;
      }

      when 'T' {
        my $table = $_;
        $!refined-config{$table} =
          $!configuration.refine( |( $table, $basename));

#        note "Table $table: basename=", $basename,
#        ";\n", $!configuration.perl(:h($!refined-config{$table})) if $!trace;
      }

#`{{
      when 'S' {
        my $table = $_;
        $!refined-config{$table} =
          $!configuration.refine(|( $table, $basename));

        note "Table $table: basename=", $basename,
        ";\n", $!configuration.perl(:h($!refined-config{$table})) if $!trace;
      }
}}
    }

    note "\nComplete configuration: ", $!configuration.perl,
         "\nRefined configuration tables"
         if $!trace and $!refined-config<T><config>;

    if $!trace and $!refined-config<T><tables> {
      note "Refine keys: $!refine[IN], $!refine[OUT]";
      note "File: $basename";
      for @$!refine-tables -> $table {
        note "Table $table:\n",
          $!configuration.perl(:h($!refined-config{$table}));
      }
    }

    # before continuing, process dependencies first
    self!run-dependencies;

    #TODO Check exitence and modification time of result to see
    # if wee need to continue parsing
    my Bool $continue = True;

    # Use the R-table if the entry is an Array. If R-table entry is an Array,
    # take the second element. It is a result filename to check for modification
    # date. Check is done before parsing to see if paqrsing is needed.
    if ?$!filename {
      my $fn;
      if $!refined-config<R>{$!refine[OUT]} ~~ Array {
        $fn = self!process-cmd-str($!refined-config<R>{$!refine[OUT]}[1]);
        $continue = !$fn.IO.e or ($!filename.IO.modified > $fn.IO.modified);
      }

      else {
        $fn = self!process-cmd-str("%op/%of.%oe");
        $continue = !$fn.IO.e or ($!filename.IO.modified > $fn.IO.modified);
      }

      if ! $continue {
        note "No need to parse and save data, $fn is newer than $!filename"
           if $!trace and $!refined-config<T><parse>;
      }
    }

    # instantiate modules specified in the configuration
    self!process-modules if $continue;

    $continue = True;
  }

  #-----------------------------------------------------------------------------
  method !run-dependencies ( ) {

#TODO compare modification times of result

    # get D-table
    my Hash $D = $!refined-config<D> // {};
    my Array $dependencies = $D{$!refine[OUT]} // [];
    for @$dependencies -> $d-spec {
      my @d = $d-spec.split(';');
      if @d.elems == 3 {

        # check if file is seen before. Set before parsing starts on dependency
        my Str $filename = @d[2];
        next if $processed-dependencies{$filename}:exists;
        $processed-dependencies{$filename} = True;

        # Bind to S table
        my Hash $S := $!refined-config<S>;

        # prefix filename with path when filename is relative
        if ?$S<filepath> {
          $filename = $S<rootpath> ~ '/' ~ $S<filepath> ~ '/' ~ $filename;
        }

        else {
          $filename = $S<rootpath> ~ '/' ~ $filename;
        }

        my Array $refine = [@d[ IN, OUT]];
        my SemiXML::Sxml $x .= new( :$!trace, :$!merge, :$refine);

        note "Process dependency @d[*]"
          if $!trace and $!refined-config<T><file-handling>;

        $x.save if $x.parse(:$filename) ~~ Match;
      }
    }
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
    note " " if $!trace and $!refined-config<T><modules>;
    for $mod.kv -> $key, $value {
      if $!objects{$key}:!exists {
        if $lib{$key}:exists {

#TODO test for duplicate paths
          my $repository = CompUnit::Repository::FileSystem.new(
            :prefix($lib{$key})
          );
          CompUnit::RepositoryRegistry.use-repository($repository);
        }

        (try require ::($value)) === Nil and die "Failed to load $value";
        my $obj = ::($value).new;
        $!objects{$key} = $obj if $obj.defined;

        note "Object for key '$key' installed from class $value"
             if $!trace and $!refined-config<T><modules>;
      }

      else {
        note "Object for '$key' already installed from class $value"
             if $!trace and $!refined-config<T><modules>;
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
          :$merge, :trace
#          :trace($!trace and ($!refined-config<T><config-search> // False))
        );
      }

      else {
        $!configuration .= new(
          :$config-name, :$locations, :$merge,
          :trace
#          :trace($!trace and ($!refined-config<T><config-search> // False))
        );
      }

      CATCH {
say "Error catched at $?LINE: ", .message;
        default {
          # Ignore file not found exception
          if .message !~~ m/ :s Config files .* not found / {
            .rethrow;
          }
        }
      }
    }
  }
}
