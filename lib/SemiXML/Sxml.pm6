use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;

use SemiXML::Grammar;
use SemiXML::Actions;
use SemiXML::Text;
use Config::DataLang::Refine;
use Terminal::ANSIColor;

use XML;

#-------------------------------------------------------------------------------
class Sxml {

  has SemiXML::Grammar $!grammar;
  has SemiXML::Actions $!actions;

  has Config::DataLang::Refine $!configuration;

  enum RKeys <<:IN(0) :OUT(1)>>;
  has Array $!refine;
  has Array $!table-names;
  has Hash $!refined-tables;

  has Hash $!objects = {};

  has Str $!filename;
  has Str $!target-fn;

  has Bool $!drop-cfg-filename;
  has Hash $!user-config;
#TODO doc and specificity of T-Table tracing
  has Bool $!trace = False;
  has Bool $!force;
  has Bool $!keep;

  # structure to check for dependencies
  my Hash $processed-dependencies = {};

  has SemiXML::Globals $!globals;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    Array :$!refine = [], Bool :$!force = False,
    Bool :$!trace = False, Bool :$!keep = False
  ) {

    $!globals .= instance;
    $!grammar .= new;
    $!actions .= new(:sxml-obj(self));

#TODO make sure that the objects read T-Table before show traces of anything
#TODO also in globals!
    $SemiXML::Actions::keep-as-typed = $!keep;

    $!globals.trace = $!trace;

    # Make sure that in and out keys are defined with defaults
    $!refine[IN] = 'xml' unless ?$!refine[IN];
    $!refine[OUT] = 'xml' unless ?$!refine[OUT];

    # Initialize the refined config tables
    $!table-names = [<C D E F H ML R S T X>];
    $!refined-tables = %(@$!table-names Z=> ( {} xx $!table-names.elems ));
  }

  #-----------------------------------------------------------------------------
  multi method parse ( Str:D :$!filename!, Hash :$config --> Bool ) {

    my Bool $pr;

    if $!filename.IO ~~ :r {
      # save the filename globally but only once
#TODO doc
      $!globals.filename //= $!filename;

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
    Str:D :$content! is copy, Hash :$config,
    Bool :$!drop-cfg-filename = True
    --> Bool
  ) {

    $!user-config = $config;
    $!filename = Str if $!drop-cfg-filename;

    # Prepare config and process dependencies. If result is newer than source
    # prepare returns False to note that further work is not needed.
    # Generate a proper Match object to return.
    return False unless self!prepare-config;

    # Parse the content. Parse can be recursively called
    my Match $m = $!grammar.subparse( $content, :actions($!actions));

    # Throw an exception when there is a parsing failure
    my $last-bracket-index = $content.rindex(']') // $content.chars;
    if $!trace and $!refined-tables<T><parse-result> {
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

    True;
  }

  #-----------------------------------------------------------------------------
  # Save file using config
  method save ( ) {

    # Get the document text
    my $document = self.Str;

    # If a run code is defined, use that code as a key to find the program
    # to send the result to. If R-table entry is an Array, take the first
    # element. The second element is a result filename to check for modification
    # date. Check is done before parsing to see if parsing is needed.
    my $cmd;
    if $!refined-tables<R>{$!refine[OUT]} ~~ Array {
      $cmd = $!refined-tables<R>{$!refine[OUT]}[0];
    }

    else {
      $cmd = $!refined-tables<R>{$!refine[OUT]};
    }

    # command is defined and non-empty
    if ?$cmd {

      $cmd = self!process-cmd-str($cmd);

      note "Send file to program: $cmd"
        if $!trace and $!refined-tables<T><file-handling>;

      my Proc $p = shell "$cmd", :in;
      $p.in.print($document);
      $p.in.close;
    }

    else {

      my $filename = self!process-cmd-str("%op/%of.%oe");

      spurt( $filename, $document);
      note "Saved file in $filename"
        if $!trace and $!refined-tables<T><file-handling>;
    }
  }

  #-----------------------------------------------------------------------------
  method Str ( --> Str ) {
    my Str $text = self.get-xml-text;

    # substitute back all single quotes. it is never a problem to
    # have them escaped
    $text ~~ s:g/'&#39;'/'/;

    $text
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
      if $!refined-tables<C><header-show> and ? $!refined-tables<H> {
        for $!refined-tables<H>.kv -> $k, $v {
          $document ~= "$k: $v\n";
        }
        $document ~= "\n";
      }

      # Check if xml prelude must be shown
      if ? $!refined-tables<C><xml-show> {
        my $version = $!refined-tables<X><xml-version> // '1.0';
        my $encoding = $!refined-tables<X><xml-encoding> // 'utf-8';
        my $standalone = $!refined-tables<X><xml-standalone>;

        $document ~= '<?xml version="' ~ $version ~ '"';
        $document ~= ' encoding="' ~ $encoding ~ '"';
        $document ~= ' standalone="' ~ $standalone ~ '"' if $standalone;
        $document ~= "?>\n";
      }

      # Check if doctype must be shown
      if ? $!refined-tables<C><doctype-show> {
        my Hash $entities = $!refined-tables<E> // {};
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

    $!refined-tables{$table}:exists ?? $!refined-tables{$table}{$key} !! Any
  }

  #-----------------------------------------------------------------------------
  method root-element ( --> XML::Element ) {
    my $doc = $!actions.get-document;
    return ?$doc ?? $doc.root !! XML::Element;
  }

  #-----------------------------------------------------------------------------
  method !process-cmd-str( Str $cmd-string --> Str ) {

    my $cmd = $cmd-string;

    # Bind to S table
    my Hash $S := $!refined-tables<S>;

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
    # first is resource and there is no merge from other configs
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
      #     (also hidden), and in $HOME.
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

    $c<S><filepath> //= '';

    # Fill the special purpose tables with the refined searches in the config
    for @$!table-names -> $table {
      # document control
      if $table ~~ any(<D E F ML R>) {
        $!refined-tables{$table} =
          $!configuration.refine( $table, $!refine[IN], $basename);
      }

      # output control
      elsif $table ~~ any(<C H S X>) {
        $!refined-tables{$table} =
          $!configuration.refine( $table, $!refine[OUT], $basename);
      }

      elsif $table eq 'T' {
        $!refined-tables{$table} =
          $!configuration.refine( $table, $basename);
      }

#`{{
      elsif $table eq 'S' {
        $!refined-tables{$table} =
          $!configuration.refine( $table, $basename);
      }
}}
    }

    note "\nComplete configuration: ", $!configuration.perl,
         "\nRefined configuration tables"
         if $!trace and $!refined-tables<T><config>;

    if $!trace and $!refined-tables<T><tables> {
      note "Refine keys: $!refine[IN], $!refine[OUT]";
      note "File: $basename";
      for @$!table-names -> $table {
        note "Table $table:\n",
          $!configuration.perl(:h($!refined-tables{$table}));
      }
    }

    # Place all the tables in the package
    #$!actions.refined-tables = $!refined-tables;
#TODO doc
    $!globals.refined-tables = $!refined-tables;

    #TODO Check exitence and modification time of result to see
    # if we need to continue parsing
    my Bool $continue = True;

    if ! $!force {

      # Use the R-table if the entry is an Array. If R-table entry is an Array,
      # take the second element. It is a result filename to check for modification
      # date. Check is done before parsing to see if parsing is needed.
      $!target-fn = 'unknown.unknown';
      if ?$!filename {
        if $!refined-tables<R>{$!refine[OUT]} ~~ Array {
          $!target-fn = self!process-cmd-str(
            $!refined-tables<R>{$!refine[OUT]}[1]
          );
        }

        else {
          $!target-fn = self!process-cmd-str("%op/%of.%oe");
        }

        $continue = (
          ! $!target-fn.IO.e or (
            $!filename.IO.modified.Int > $!target-fn.IO.modified.Int
          )
        );
      }
    }

    # before continuing, process dependencies first. $!target-fn is used there
    my Bool $found-dependency = self!run-dependencies;

    # instantiate modules specified in the configuration
    if $found-dependency or $continue {
      self!process-modules;
    }

    else {
      note "No need to parse and save data, $!target-fn is in its latest version"
           if $!trace and $!refined-tables<T><parse>;
    }

    $found-dependency or $continue
  }

  #-----------------------------------------------------------------------------
  method !run-dependencies ( --> Bool ) {

#TODO compare modification times of result
    my Bool $dependency-found = False;

    # get D-table. selection is already made on in-key
    my Hash $D = $!refined-tables<D> // {};
    # select the entry pointed by the out-key. this must be an array of
    # dependency specs
    my $d = $D{$!refine[OUT]} // [];
    my Array $dependencies = $d ~~ Array ?? $d !! [$d];
    for @$dependencies -> $d-spec {
      # a spec is like [in-key;out-key;dep-file]
      my @d = $d-spec.split(/\s* ';' \s*/);
      if @d.elems == 3 {

        # check if file is seen before. Set before parsing starts on dependency
        my Str $filename = @d[2];
        next if $processed-dependencies{$filename}:exists;
        $processed-dependencies{$filename} = True;

        # get S table
        my Hash $S := $!refined-tables<S>;

        # prefix filename with path when filename is relative
        if ?$S<filepath> {
          $filename = [~] $S<rootpath>, '/', $S<filepath>, '/', $filename;
        }

        else {
          $filename = $S<rootpath> ~ '/' ~ $filename;
        }

        # if one of the IN or OUT keys is a '-' then it is supposed not to
        # do any work but compare the modification time of the file with that
        # of the target
        if @d[IN] eq '-' or @d[OUT] eq '-' {

          $dependency-found = (
            ! $!target-fn.IO.e or (
              $!filename.IO.modified.Int > $!target-fn.IO.modified.Int
            )
          );
        }

        else {

          my Array $refine = [@d[ IN, OUT]];
          my SemiXML::Sxml $x .= new( :$!trace, :$refine);

          note "Process dependency: --in=@d[IN] --out=@d[OUT] $filename"
            if $!trace and $!refined-tables<T><file-handling>;

          if $x.parse(:$filename) {
            $x.save;
            $dependency-found = True;
          }
        }
      }
    }

    $dependency-found
  }

  #-----------------------------------------------------------------------------
  # Get modulenames and library paths. Format of an entry in table ML is
  # mod-key => 'mod-name[;lib-path]'
  method !process-modules ( ) {

    # no entries, no work
    return unless ? $!refined-tables<ML>;

    my Hash $lib = {};
    my Hash $mod = {};
    for $!refined-tables<ML>.keys -> $modkey {

      next unless ? $!refined-tables<ML>{$modkey};

      ( my $m, my $l) = $!refined-tables<ML>{$modkey}.split(';');
      $lib{$modkey} = $l if $l;
      $mod{$modkey} = $m;
    }

    # cleanup old objects
    for $!objects.keys -> $k {
      undefine $!objects{$k};
      $!objects{$k}:delete;
    }

    # load and instantiate
    note " " if $!trace and $!refined-tables<T><modules>;
    for $mod.kv -> $key, $value {
      if $!objects{$key}:!exists {
        if $lib{$key}:exists {

#TODO test for duplicate paths
          my $repository = CompUnit::Repository::FileSystem.new(
            :prefix($lib{$key})
          );
          CompUnit::RepositoryRegistry.use-repository($repository);
        }

        (try require ::($value)) === Nil and say "Failed to load $value\n$!";
        my $obj = ::($value).new;
        $!objects{$key} = $obj if $obj.defined;

        note "Object for key '$key' installed from class $value"
             if $!trace and $!refined-tables<T><modules>;
      }

      else {
        note "Object for '$key' already installed from class $value"
             if $!trace and $!refined-tables<T><modules>;
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
    Str :$config-name, Array :$locations = [], Bool :$merge
  ) {

    try {

      # $!configuration is always undefined the first time.
      if $!configuration.defined {
        $!configuration .= new(
          :$config-name, :$locations, :other-config($!configuration.config),
          :$merge, :$!trace
        );
      }

      else {
        $!configuration .= new( :$config-name, :$locations, :$merge, :$!trace);
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
