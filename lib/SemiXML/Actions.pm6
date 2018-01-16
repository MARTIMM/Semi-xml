use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML::SxmlElement;
use SemiXML::SxmlBody;
use SemiXML::SxmlContent;
use SemiXML::SxmlText;


#-------------------------------------------------------------------------------
class Actions {

  # The root should only have one element. When there are more, convert
  # the result into a fragment.
  has SemiXML::SxmlElement $!root;
  has SemiXML::SxmlElement $!element;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {
    $!root .= new(:name<root>);
  }



  #-----------------------------------------------------------------------------
  method TOP ( $match ) {

  }

  #-----------------------------------------------------------------------------
  method document ( $match ) {

  }

  #-----------------------------------------------------------------------------
  method tag-spec ( $match ) {
note "\nTS: $match";

    my Hash $attributes = self!attributes([$match<attributes>.caps]);

    my $tag = $match<tag>;

    my Str $symbol = $tag<sym>.Str;
    if $symbol eq '$' {
      $!element .= new( :name($tag<tag-name>.Str), :$attributes);
    }

    elsif $symbol eq '$!' {
      $!element .= new(
        :module($tag<mod-name>.Str), :method($tag<meth-name>.Str),
        :$attributes
      );
    }

    # set root element if this is the first element
    #$!element.parent = ...
note $!element.perl;
  }

  #-----------------------------------------------------------------------------
  method tag-bodies ( $match ) {

  }




  #-----------------------------------------------------------------------------
  method !attributes ( Array $attr-specs --> Hash ) {

    # define the attributes for the element. attr value is of type StringList
    # where ~$strlst gives string, @$strlst returns list and $strlist.value
    # either string or list depending on :use-as-list which in turn depends
    # on the way an attribute is defined att='val1 val2' or att=<val1 val2>.
    my Hash $attrs = {};
    for @$attr-specs -> $as {
      next unless $as<attribute>:exists;
      my $a = $as<attribute>;
      my SemiXML::StringList $av;

      # when =attr is same as attr=1
      if ? $a<bool-true-attr> {
        $av .= new( :string<1>, :!use-as-list);
      }

      # when =!attr is same as attr=0
      elsif ? $a<bool-false-attr> {
        $av .= new( :string<0>, :!use-as-list);
      }

      else {
        # when attr=<a b c> attr-list-value is set
        $av .= new(
          :string($a<attr-value-spec><attr-value>.Str),
          :use-as-list(?($a<attr-value-spec><attr-list-value> // False))
        );
      }

      $attrs{$a<attr-key>.Str} = $av;
    }

    $attrs;
  }

  #-----------------------------------------------------------------------------
  # temporary provision for the calling module returning an empty doument
  use XML;
  method get-document ( --> XML::Document ) {

    my XML::Element $r .= new(:name<root>);
    return XML::Document.new(:root($r));
  }
}







=finish

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Text;
use SemiXML::StringList;
use SemiXML::ContentBodies;
use SxmlLib::SxmlHelper;
use XML;
use XML::XPath;

#-------------------------------------------------------------------------------
class Actions {

  # get global object to get tracing info
  has SemiXML::Globals $!globals .= instance;

  has XML::Document $!xml-document;

  # Keep current state of affairs. Hopefully some info when parsing fails
  has Int $.from;
  has Int $.to;
  has Str $.prematch;
  has Str $.postmatch;
  has Str $.state;

  has Array $.unleveled-brackets = [];
  has Array $.mismatched-brackets = [];

  # Save a list of tags from root to deepest level. This is possible because
  # body is processed later than tag-spec. The names are the element name,
  # method name or symbol name. The xml namesspace and module name are not
  # added because these can be any name defined by the user.
  has Array $!tag-list = [];

  #-----------------------------------------------------------------------------
  method init-doc ( $match ) {

    self!current-state( $match, 'initializing doc');
    state $init-to-fail =
      XML::Element.new(:name<failed-to-parse-sxml-document>);
    $!xml-document .= new($init-to-fail);
  }

  #-----------------------------------------------------------------------------
  method TOP ( $match ) {

    my Bool $trace = $!globals.trace and $!globals.refined-tables<T><parse>;
    self!current-state( $match, 'at the top');

    my $parent = $match<document>.made;

#note "Raw: $!globals.raw()";
#note "\n$parent";
#exit(0);
    unless $!globals.raw {
      drop-parent-container($parent);

      # process top level method container
      if $parent.name eq 'sxml:parent_container' {
        if +$parent.nodes == 0 {
          # No nodes generated
          $parent = XML::Element.new;
        }

        elsif +$parent.nodes == 1 {
          # One node generated
          $parent = $parent.nodes[0];
        }

        else {
          my $tag-ast = $match<document><tag-spec>.made;
          $parent = XML::Element.new(
            :name('method-generated-too-many-nodes'),
            :attribs( module => $tag-ast[3], method => $tag-ast[4])
          );
        }
      }

      # search for variables and substitute them
      subst-variables($parent);
      note "After variable sub: $parent" if $trace;

      # move around some elements
      remap-content($parent);
      note "After remapping: $parent" if $trace;

      # process everything and modify according to the F-Table
      apply-f-table($parent);
      note "After applying the F-Table: $parent" if $trace;

      # remove leftovers from sxml namespace
      remove-sxml($parent);
      note "After ns removal: $parent" if $trace;

      note '-' x 80 if $trace;
    }

    # return the completed document
    $!xml-document .= new($parent);
    $!xml-document
  }

  #---------------------------------------------------------------------------
  method pop-tag-from-list ( $match ) {

#TODO only after the last block. Also when no block is found!
    # This level is done so drop an element tag from the list
    $!tag-list.pop;
  }

  #-----------------------------------------------------------------------------
  method document ( $match ) {

    self!current-state( $match, 'document');

#`{{
    # Try to find indent level to match up open '[' with close ']'.
    #
    # 1) $x                     no body at all
    # 2) $x [ ]                 no newline in body
    # 3) $x [                   with newline, the ']' should line up with $x.
    #    ]
    # 4) $x [ ][ ]              multiple bodies no newline
    # 5) $x [                   idem with newline in first body. 1st ']'
    #    ][                     lines up with $x. When in 2nd, the 2nd ']'
    #    ]                      should also line up with $x
    # 6) $x [ $y [ ] ]          nested bodies no newline
    # 7) $x [                   with newline, outer ']' should line up
    #      $y [                 with $x and inner ']' with $y.
    #      ]
    #    ]
    #
    my Str $orig = $match.orig;

    my Array $tag-bodies = $match<tag-bodies>;
    loop ( my $mi = 0; $mi < $tag-bodies.elems; $mi++ ) {

      my Int $b-from = $match.from;
      my Int $b-to = $match.to;

#TODO test for ] in special bodies and for !] in non-special ones
      # test for special body
      my Bool $special-body = ?$orig.substr(
        $b-from, $b-to - $b-from
      ) ~~ m/^ '[!' | '<<' | '«' /;

#note "Doc $mi:, $special-body, >>>", $orig.substr( $b-from, $b-to - $b-from), "<<<";

      # find start of body
      my Int $bstart = $orig.substr(
        $b-from, $b-to - $b-from
      ).index('[') + $b-from;

      # find end of body, search from the end
      my Int $bend;
      if $special-body {
        #$bend = $orig.substr( $bstart, $b-to - $bstart).rindex('!]');
        $orig.substr( $bstart, $b-to - $bstart) ~~ / '!]' || '>>' || '»' $/;

#        if ?$bend {
#           $bend += $bstart;
        if ? $/ {
          $bend = $/.from + $bstart;
        }

        else {
          note "special body $special-body, $bstart, $b-to - $bstart";
          note "$orig.substr( $bstart, $b-to - $bstart)";
        }
      }

      else {
        $bend = $orig.substr( $bstart, $b-to - $bstart).rindex(']') + $bstart;
        #$orig.substr( $bstart, $b-to - $bstart) ~~ / '!]' || '>>' || '»' $/;
        #if ? $/ {
        #  $bend = $/.from + $bstart;
        #}

#        else {
#          note "special body $special-body, $bstart, $b-to - $bstart";
#          note "$orig.substr( $bstart, $b-to - $bstart)";
#        }
      }

      # check for newlines in this body
      my Bool $has-nl = (
        $orig.substr( $bstart, $bend - $bstart).index("\n")
      ).defined;

#note "BE: $bstart, $bend, $has-nl";
      # if there is a newline, check alignment
      if $has-nl {

        my Int $tag-loc = $match<tag-spec>.from;
        my Int $indent-start =
            $tag-loc - ($orig.substr( 0, $tag-loc).rindex("\n") // -1) - 1;

        my Int $indent-end =
            $bend - ($orig.substr( 0, $bend).rindex("\n") // -1) - 1;
#note "NLDoc  $tag-loc, $indent-start, $indent-end, $bstart, $bend";

        # make a note when indents are not the same, it might reveal a
        # missing bracket.
        if $indent-start != $indent-end {

          # get line numbers of begin and end of body
          $orig.substr( 0, $tag-loc) ~~ m:g/ (\n) /;
          my Int $line-begin = $/.elems + 1;

          $orig.substr( 0, $bend) ~~ m:g/ (\n) /;
          my Int $line-end = $/.elems + 1;

          # save data
          my $bracket-info := $!unleveled-brackets;
          $bracket-info := $.mismatched-brackets
            if $orig.substr( $tag-bodies[$mi].to - 3, 3) ~~ m/ '!]' || '>>' || '»' /;

          $bracket-info.push: {
            tag-name => $match<tag-spec><tag>.Str,
            :$line-begin,
            :$line-end,
            body-count => $mi + 1
          };
        }
      }
    }
}}

    my XML::Element $x;

    ( my $tt,                 # tag type
      my $ns, my $tn,         # namespace and tag name
      my $mod, my $meth,      # module and method
      my $attrs               # attributes
    ) = @($match<tag-spec>.made);
#note "doc attrs: ", $attrs.WHAT;
#for $attrs.keys -> $k { note "Key $k: ", $attrs{$k}.WHAT; };

    # Check the node type
    given $tt {

      # Any normal tag
      when '$' {

        my Str $tag = (?$ns ?? "$ns:" !! '') ~ $tn;
        note "  Tag: $tt$tag"
          if $!globals.trace and $!globals.refined-tables<T><parse>;

        # A bit of hassle to get the StringList values converted into
        # Str explicitly
        $x .= new(
          :name($tag), :attribs(%($attrs.keys Z=> $attrs.values>>.Str))
        );

        # Check for xmlns uri definitions and set them on the current node
        for $attrs.keys {
          when m/^ 'xmlns:' ( <before '='>* ) $/ {
            my $ns-prefix = $0;
            $x.setNamespace( ~$attrs{$_}, $0);
          }
        }

        note "  Attr keys: $x.attribs().keys()"
          if $!globals.trace and $!globals.refined-tables<T><parse>;

        # Call to modify $match as a side effect
        #self!build-content-body( $match, $x);
#TODO this must change
        my SemiXML::ContentBodies $cb .= new( :$match, :node($x));
      }

      # Method tag
      when '$!' {

        # Get the module if it exists
        my $module = self!can-method( $mod, $meth, :!optional);

        # When module and/or method is not found an error is generated in the
        # form of XML.
        if $module ~~ XML::Element {
#TODO show error message
          $x = $module;
        }

        # Otherwise it is the module on which method can be called
        else {
#note "Method call $module.\"$meth\", attribs: ", $attrs;

          # call user method and expect result in $x
          $x = $module."$meth"(
            XML::Element.new(:name('sxml:parent_container')),
            $attrs,
            :content-body(
              SemiXML::ContentBodies.new(
                :$match,
                :node(XML::Element.new(:name('sxml:parent_container')))
              )
            ),
            :$!tag-list
          );

          if not $x.defined {
            $x .= new(
              :name('method-returned-no-result'),
              :attribs( module => $mod, method => $meth)
            );
#TODO show error message
          }
        }
      }
    }

    # Set AST on node document
    $match.make($x);
  }

#`{{
  #-----------------------------------------------------------------------------
  method !build-content-body (
    Match $match, XML::Element $parent
    --> XML::Element
  ) {

    my Array $tag-bodies = $match<tag-bodies>;
    loop ( my $mi = 0; $mi < $tag-bodies.elems; $mi++ ) {

      note "  Body count: {$mi+1}"
        if $!globals.trace and $!globals.refined-tables<T><parse>;

      my $match = $tag-bodies[$mi];
      for @($match.made) {

        when Array {
          my Str $txt = $_[0];
          if ? $txt {
            # only spaces between texts (loop count $mi > 0)
            $parent.append(SemiXML::Text.new(:text(' '))) if $mi;

            # insert the text
            $parent.append(SemiXML::Text.new(:text($txt)));

            # add a content type attribute in the element using the SemiXML
            # namespace
            #unless $parent.name eq 'sxml:parent_container' {
              $parent.set( 'sxml:content', $_[1]);
note "Set sxml:content of $parent.name() to $_[1]";
            #}

            note "  Text: $txt.substr( 0, 68) ..."
              if $!globals.trace and $!globals.refined-tables<T><parse>;
          }
        }

        # Nested document: Ast holds { :tag-ast, :body-ast, :doc-ast}
        when Hash {
note "\nAst tag: ", $_<tag-ast>;
#note "Ast body[0]: ", $_<body-ast>[0] // '-';
note "Ast body[0] keys: ", $_<body-ast>[0].keys;
for $_<body-ast>[0].keys -> $key { note "B0 $key: ", $_<body-ast>[0]{$key} }
#note "Ast doc: ", $_<doc-ast>;
          # tag ast: [ tag type, namespace, tag name, module, method, attributes ]
          my Array $tag-ast = $_<tag-ast>;
#note "  Tag hash keys: $_.keys()";


          my $d = $_<doc-ast>;

          note "  Doc Ast: {(~$d).substr( 0, 65)} ..."
            if $!globals.trace and $!globals.refined-tables<T><parse>;
          $parent.append($d);
note "P: $parent.name()";
          note "  Result: {(~$parent).substr( 0, 66)} ..."
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }
      }
    }

    $parent;
  }
}}

  #-----------------------------------------------------------------------------
  method tag-spec ( $match ) {

    self!current-state( $match, 'tag specification');

    # Name of element or method to be saved in array $!tag-list on $!level
    my Str $tag-name;
    my Array $ast = [];
    my Str $symbol = $match<tag><sym>.Str;
    $ast.push: $symbol;

    # define the attributes for the element. attr value is of type StringList
    # where ~$strlst gives string, @$strlst returns list and $strlist.value
    # either string or list depending on :use-as-list which in turn depends
    # on the way an attribute is defined att='val1 val2' or att=<val1 val2>.
    my Hash $attrs = {};
    for $match<attributes>.caps -> $as {
      next unless $as<attribute>:exists;
      my $a = $as<attribute>;
      my SemiXML::StringList $av;

      # when =attr is same as attr=1
      if ? $a<bool-true-attr> {
        $av .= new( :string<1>, :!use-as-list);
      }

      # when =!attr is same as attr=0
      elsif ? $a<bool-false-attr> {
        $av .= new( :string<0>, :!use-as-list);
      }

      else {
        # when attr=<a b c> attr-list-value is set
        $av .= new(
          :string($a<attr-value-spec><attr-value>.Str),
          :use-as-list(?($a<attr-value-spec><attr-list-value> // False))
        );
      }

      $attrs{$a<attr-key>.Str} = $av;
    }

    if $symbol eq '$' {

      my $tn = $match<tag><tag-name>;
      $ast.push: ($tn<namespace> // '').Str, $tn<element>.Str, '', '';
      $tag-name = $tn<element>.Str;
    }

    elsif $symbol eq '$!' {

      my $tn = $match<tag>;
      $ast.push: '', '', $tn<mod-name>.Str, $tn<meth-name>.Str;
      $tag-name = $tn<meth-name>.Str;

      # Check if there is a method initialize in the module. If so call it
      # with the found attributes.
      my $module = self!can-method( $tn<mod-name>.Str, 'initialize');
      $module.initialize( $attrs, :method($tn<meth-name>.Str)) if $module;
    }

    # Add to the list
    $!tag-list.push($tag-name);

    $ast.push: $attrs;

    # Set AST on node tag-name
    $match.make($ast);
  }

  #-----------------------------------------------------------------------------
  method tag-bodies ( $match ) {

    self!current-state( $match, 'tag body');
    my Array $ast = [];
    for $match.caps -> $pair {

      my $k = $pair.key;
      my $v = $pair.value;

      note "  Body type: $k"
        if $!globals.trace and $!globals.refined-tables<T><parse>;

      given ~$k {
        # Body like [ ... ]
        when 'body-a' {
          note "  body a: $v.substr( 0, 66) ..."
            if $!globals.trace and $!globals.refined-tables<T><parse>;

          $ast.push: { :text($v.Str), :type<A>};
        }

        # Body like { ... }
        when 'body-b' {
          note "  body b: $v.substr( 0, 66) ..."
            if $!globals.trace and $!globals.refined-tables<T><parse>;

          $ast.push: { :text($v.Str), :type<B>};
        }

        # Body like « ... »
        when 'body-c' {
          note "  body c: $v.substr( 0, 66) ..."
            if $!globals.trace and $!globals.refined-tables<T><parse>;

          $ast.push: { :text($v.Str), :type<C>};
        }

        when 'document' {
          note "  Document: {(~$v).substr( 0, 64)} ..."
            if $!globals.trace and $!globals.refined-tables<T><parse>;

          my $tag-ast = $v<tag-spec>.made;
          my $body-ast = $v<tag-bodies>;
          $ast.push: { :$tag-ast, :$body-ast, :doc-ast($v.made)};
        }
      }

      note " " if $!globals.trace and $!globals.refined-tables<T><parse>;
    }

    note " " if $!globals.trace and $!globals.refined-tables<T><parse>;

    # Set AST on node tag-bodies
    $match.make($ast);
  }

  #-----------------------------------------------------------------------------
  # Return object if module and method is found. Otherwise return Any
  method !can-method ( Str $mod-name, $meth-name, Bool :$optional = True ) {

    my XML::Element $x;

    my $module = $!globals.objects{$mod-name}
      if $!globals.objects{$mod-name}:exists;

    if $module.defined {
      if $module.^can($meth-name) {
        $module;
      }

      else {
        $x .= new(
          :name('undefined-method'),
          :attribs( module => $mod-name, method => $meth-name)
        ) unless $optional;
      }
    }

    else {
      $x .= new( :name('undefined-module'), :attribs(module => $mod-name))
        unless $optional;
    }
  }

#`{{
  #-----------------------------------------------------------------------------
  method !clean-text (
    Str $t is copy, Bool :$fixed = False, Bool :$comment = True
    --> Str
  ) {

    #$t ~~ s/^ '!' '='? //;
    #$t ~~ s/ '!' $//;

    # filter comments
    $t ~~ s:g/ <.ws> '#' \N* \n // if $comment;
    $t ~~ s:g/^ '#' \N* \n // if $comment;

    # remove trailing spaces at every line
    $t ~~ s:g/ \h+ $$ //;

    # remove leading spaces for the minimum number of spaces when the content
    # should be fixed
    if $fixed {
      my Int $min-indent = 1_000_000_000;
      for $t.lines -> $line {
        $line ~~ m/^ $<indent>=(\s*) /;
        my Int $c = $/<indent>.Str.chars;

        # adjust minimum only when there is something non-spacical on the line
        $min-indent = $c if $line ~~ m/\S/ and $c < $min-indent;
      }

      my $new-t = '';
      my Str $indent = ' ' x $min-indent;
      for $t.lines {
        my $l = $^line;
        $l ~~ s/^ $indent//;
        $new-t ~= "$l\n";
      }
      $t = $new-t;
    }

    else {
      # remove leading spaces at begin of text
      $t ~~ s/^ \s+ //;

      # substitute multiple spaces with one space
      $t ~~ s:g/ \s\s+ / /;

      # remove return characters if found
      $t ~~ s:g/ \n+ / /;
    }

    $t;
  }
}}
  #-----------------------------------------------------------------------------
  method !current-state ( Match $match, Str $state ) {

    $!from = $match.from;
    $!to = $match.to;
    $!prematch = $match.prematch;
    $!postmatch = $match.postmatch;
    $!state = $state;
  }

#`{{
  #-----------------------------------------------------------------------------
  method Xset-objects( Hash:D $objects ) {

    $!objects = $objects;
  }
}}

#`{{
  #-----------------------------------------------------------------------------
  method Xprocess-modules ( Hash :$lib = {}, Hash :$mod = {} ) {

    # cleanup old objects
    for $!objects.keys -> $k {
      undefine $!objects{$k};
      $!objects{$k}:delete;
    }

    for $mod.kv  -> $key, $value {
      if $!objects{$key}:!exists {
        if $lib{$key}:exists {

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
  }
}}

  #-----------------------------------------------------------------------------
  method get-document ( --> XML::Document ) {

    return $!xml-document;
  }
}
