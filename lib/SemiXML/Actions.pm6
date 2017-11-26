use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<https://github.com/MARTIMM>;

use XML;
use XML::XPath;
use SemiXML::Text;
use SemiXML::StringList;

#-------------------------------------------------------------------------------
class Actions {

  # Caller SemiXML::Sxml object
  has $!sxml-obj;

  # Objects hash with one predefined object for core methods
  has Hash $.objects is rw = {};
  has XML::Document $!xml-document;

  # The F-table is devised elsewhere as well. This table is read from the config
  has Hash $.F-table is rw = {};

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
  #
  has Array $!tag-list = [];

  #-----------------------------------------------------------------------------
#TODO can we remove the BUILD?
  submethod BUILD ( :$!sxml-obj ) { }

  #-----------------------------------------------------------------------------
  method init-doc ( $match ) {

    self!current-state( $match, 'initializing doc');
    state $init-to-fail =
      XML::Element.new(:name<failed-to-parse-sxml-document>);
    $!xml-document .= new($init-to-fail);
  }

  #-----------------------------------------------------------------------------
  method TOP ( $match ) {

    self!current-state( $match, 'at the top');

    my $parent = $match<document>.made;

    # Cleanup residue tags left from processing methods. The childnodes in
    # '__PARENT_CONTAINER__' tags must be moved to the parent of it. There
    # is one exception, that is when the tag is at the top. Then there may
    # only be one tag. If there are more, an error tag is generated.
    #
    my $containers = $parent.elements(
      :TAG<__PARENT_CONTAINER__>,
      :RECURSE, :NEST,
    );

    for @$containers -> $node {

      my $children = $node.nodes;

      # eat from the end of the list and add just after the container element.
      # somehow they get lost from the array when done otherwise.
      #
      for @$children.reverse {
        $node.parent.after( $node, $^a);
      }

      # remove the now empty element
      $node.remove;
    }

    # process top level method container
    if $parent.name eq '__PARENT_CONTAINER__' {
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

    # conversion to xml escapes is done as late as possible
    my Sub $after-math = sub ( XML::Element $x ) {

      # process body text to escape special chars
      for $x.nodes -> $node {
        if $node ~~ any( SemiXML::Text, XML::Text) {
          my Str $s = self!process-esc(~$node);
          $node.parent.replace( $node, SemiXML::Text.new(:text($s)));
        }

        elsif $node ~~ XML::Element {
          my Array $self-closing = $!F-table<self-closing> // [];

#note "Ftab: ", $self-closing;
          # Check for self closing tag, and if so remove content if any
          if $node.name ~~ any(@$self-closing) {
#note "Found self closing tag: $node.name()";
            # elements not able to contain any content; remove any content
            for $node.nodes.reverse -> $child {
              $node.removeChild($child);
            }
          }

          else {
            # recurively process through all elements
            $after-math($node);

            # If this is not a self closing element and there is no content, insert
            # an empty string to get <a></a> instead of <a/>
            if ! $node.nodes {
              $node.append(SemiXML::Text.new(:text('')));
            }
          }
        }

#        elsif $node ~~ any(XML::Text|SemiXML::Text) {
#
#        }
      }
    }

    &$after-math($parent);


    # create completed document
    $!xml-document .= new($parent);
    $parent.setNamespace( 'github.MARTIMM', 'sxml');

    # search for variables and substitute them
    my $x = XML::XPath.new(:document($!xml-document));
    $x.set-namespace: 'sxml' => 'github.MARTIMM';
    for $x.find( '//sxml:variable', :to-list) -> $vdecl {

      my $vd = $vdecl.clone;

      my Str $var-name = ~$vd.attribs<name>;
      my @var-value = $vd.nodes;
      my Bool $var-global = $vd.attribs<global>:exists;

      my @var-use;
      if $var-global {
        @var-use = $x.find( '//sxml:' ~ $var-name, :to-list);
      }

      else {
        @var-use = $x.find(
          './/sxml:' ~ $var-name, :start($vd.parent), :to-list
        );
      }

      for @var-use -> $vuse {
        for $vd.nodes -> $vdn {
          my XML::Node $x = self.clone-node($vdn);
          $vuse.parent.before( $vuse, $x);
        }

        $vuse.remove;
      }

      $vd.remove;
    }

    # show some leftover sxml namespace elements
    for $x.find( '//*', :to-list) -> $v {
      if $v.name() ~~ /^ 'sxml:'/ {
        note "Leftovers in sxml namespace: '$v.name()', parent is '$v.parent.name()'";
        $v.remove;
      }
    }

    # remove the namespace
    $parent.attribs{"xmlns:sxml"}:delete;

    # return the completed document
    $!xml-document
  }

  #---------------------------------------------------------------------------
  method clone-node ( XML::Node $node --> XML::Node ) {

    my $clone;

    if $node ~~ XML::Element {

#note "Node is element, name: $node.name()";
      $clone = XML::Element.new( :name($node.name), :attribs($node.attribs));
      $clone.idattr = $node.idattr;

      $clone.nodes = [];
      for $node.nodes -> $n {
        $clone.nodes.push: self.clone-node($n);
      }
    }

    elsif $node ~~ XML::Text {
#note "Node is text";
      $clone = XML::Text.new(:text($node.text));
    }

    elsif $node ~~ SemiXML::Text {
#note "Node is text";
      $clone = SemiXML::Text.new(:text($node.txt));
    }

    else {
#note "Node is ", $node.WHAT;
      $clone = $node.cloneNode;
    }

#note "Clone: ", $clone.perl;
    $clone
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

    # Try to find indent level to match up open '[' with close ']'.
    #
    # 1) $x                     no body at all
    # 2) $x [ ]                 no newline in body
    # 3) $x [                   with newline, the ']' should line up with $x.
    #    ]
    # 4) $x [ ] [ ]             multiple bodies no newline
    # 5) $x [                   idem with newline in first body. 1st ']'
    #    ] [                    lines up with $x. When in 2nd, the 2nd ']'
    #    ]                      should also line up with $x
    # 6) $x [ $y [ ] ]          nested bodies no newline
    # 7) $x [                   with newline, outer ']' should line up
    #      $y [                 with $x and inner ']' with $y.
    #      ]
    #    ]
    #
    my Str $orig = $match.orig;

    my Array $tag-bodies = $match<tag-body>;
    loop ( my $mi = 0; $mi < $tag-bodies.elems; $mi++ ) {

      my Int $b-from = $match.from;
      my Int $b-to = $match.to;

#TODO test for ] in special bodies and for !] in non-special ones
      # test for special body
      my Bool $special-body = ?$orig.substr(
        $b-from, $b-to - $b-from
      ) ~~ m/^ '[!' /;

      $orig.substr( $tag-bodies[$mi].to - 3, 3);

      # find start of body
      my Int $bstart = $orig.substr(
        $b-from, $b-to - $b-from
      ).index('[') + $b-from;

      # find end of body, search from the end
      my Int $bend;
      if $special-body {
        $bend = $orig.substr( $bstart, $b-to - $bstart).rindex('!]');

        if ?$bend {
           $bend += $bstart;
        }

        else {
          note "special body $special-body, $bstart, $b-to - $bstart";
          note "$orig.substr( $bstart, $b-to - $bstart)";
        }
      }

      else {
        $bend = $orig.substr(
          $bstart, $b-to - $bstart
        ).rindex(']') + $bstart;
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
            if $orig.substr( $tag-bodies[$mi].to - 3, 3) ~~ m/ '!]' /;

          $bracket-info.push: {
            tag-name => $match<tag-spec><tag>.Str,
            :$line-begin,
            :$line-end,
            body-count => $mi + 1
          };
        }
      }
    }

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
      when any(< $** $*| $|* $ >) {

        my Str $tag = (?$ns ?? "$ns:" !! '') ~ $tn;

        # A bit of hassle to get the StringList values converted into Str explicitly
        $x .= new( :name($tag), :attribs(%($attrs.keys Z=> $attrs.values>>.Str)));

        # Check for xmlns uri definitions and set them on the current node
        for $attrs.keys {
          when m/^ 'xmlns:' ( <before '='>* ) $/ {
            my $ns-prefix = $0;
            $x.setNamespace( ~$attrs{$_}, $0);
          }
        }

        self!build-content-body( $match, $x);
      }

      # Method tag
      when '$!' {

        # Get the module if it exists
        my $module = self!can-method( $mod, $meth, :!optional);

        # When module and/or method is not found an error is generated in the
        # form of XML.
        if $module ~~ XML::Element {
          $x = $module;
        }

        # Otherwise it is the module on which method can be called
        else {
#note "Method call attribs: ", $attrs;

          # call user method and expect result in $x
          $x = $module."$meth"(
            XML::Element.new(:name('__PARENT_CONTAINER__')),
            $attrs,
            :content-body(
              self!build-content-body(
                $match,
                XML::Element.new(:name('__PARENT_CONTAINER__'))
              )
            ),
            :$!tag-list
          );

          if not $x.defined {
            $x .= new(
              :name('method-returned-no-result'),
              :attribs( module => $mod, method => $meth)
            );
          }
        }
      }
    }

    # Set AST on node document
    $match.make($x);
  }

  #-----------------------------------------------------------------------------
  method !build-content-body (
    Match $match, XML::Element $parent
    --> XML::Element
  ) {

    my Array $comments = $match<comment>;
    my Array $tag-bodies = $match<tag-body>;
    loop ( my $mi = 0; $mi < $tag-bodies.elems; $mi++ ) {

      my $match = $tag-bodies[$mi];
      for @($match.made) {

        # Any piece of found text in bodies. Filter out any comments.
        when Str {
          my Str $txt = $_;
          if ? $txt {
#TODO maybe all lines prefixed with a space and one at the end.
            $parent.append(SemiXML::Text.new(:text(' '))) if $mi;
            $parent.append(SemiXML::Text.new(:text($txt)));
          }
        }

        # Nested document: Ast holds { :tag-ast, :body-ast, :doc-ast}
        when Hash {
#note "Ast hash: ", $_.keys;
#note "Ast tag: ", $_<tag-ast>;
#note "Ast body: ", $_<body-ast>;
#note "Ast doc: ", $_<doc-ast>;
          # tag ast: [ tag type, namespace, tag name, module, method, attributes ]
          my Array $tag-ast = $_<tag-ast>;

#TODO see above
          # Test if spaces are needed before the document
          $parent.append(SemiXML::Text.new(:text(' ')))
            if $tag-ast[0] ~~ any(< $** $*| >);

          $parent.append($_<doc-ast>);

#TODO see above
          # Test if spaces are needed after the document
          $parent.append(SemiXML::Text.new(:text(' ')))
            if $tag-ast[0] ~~ any(< $** $|* >);
        }
      }
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  method tag-spec ( $match ) {

    self!current-state( $match, 'tag specification');

    # Name of element or method to be saved in array $!tag-list on $!level
    my Str $tag-name;
    my Array $ast = [];
    my Str $symbol = $match<tag><sym>.Str;
    $ast.push: $symbol;
#note "Tag: ", $match<tag>.kv;

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
#note "AV $a<attr-key>: ", $av;
      $attrs{$a<attr-key>.Str} = $av;
    }

    if $symbol ~~ any(< $** $|* $*| $ >) {

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
      $module.initialize(
        $!sxml-obj, $attrs, :method($tn<meth-name>.Str)
      ) if $module;
    }

    # Add to the list
    $!tag-list.push($tag-name);
#note "Tag name: $tag-name";

    $ast.push: $attrs;

    # Set AST on node tag-name
    $match.make($ast);
  }

  #-----------------------------------------------------------------------------
  method tag-body ( $match ) {

    self!current-state( $match, 'tag body');
    my Array $ast = [];
    for $match.caps {

      # keys can be body1-contents..body4-contents
      my $p = $^a.key;
      my $v = $^a.value;

      # Text cannot have nested documents and text must be taken literally
      if $p eq 'body1-contents' {

        $ast.push: self!clean-text( $v<body2-text>.Str, :fixed, :!comment);
      }

      # Text cannot have nested documents and text may be re-formatted
      elsif $p eq 'body2-contents' {

        $ast.push: self!clean-text( $v<body2-text>.Str, :!fixed, :!comment);
      }

      # Text can have nested documents and text must be taken literally
      if $p eq 'body3-contents' {

        for $match<body3-contents>.caps {

          # keys can be body1-text or document
          my $p3 = $^a.key;
          my $v3 = $^a.value;

          # body1-text
          if $p3 eq 'body1-text' {

            $ast.push: self!clean-text( $v3.Str, :fixed, :comment);
          }

          # document
          elsif $p3 eq 'document' {

            my $d = $v3;
            my $tag-ast = $d<tag-spec>.made;
            my $body-ast = $d<tag-body>;
            $ast.push: { :$tag-ast, :$body-ast, :doc-ast($d.made)};
          }
        }
      }

      # Text can have nested documents and text may be re-formatted
      elsif $p eq 'body4-contents' {

        # walk through all body pieces
        for $match<body4-contents>.caps {

          # keys can be body1-text or document
          my $p4 = $^a.key;
          my $v4 = $^a.value;

          # body1-text
          if $p4 eq 'body1-text' {

            $ast.push: self!clean-text( $v4.Str, :!fixed, :comment);
          }

          # document
          elsif $p4 eq 'document' {

            my $d = $v4;
            my $tag-ast = $d<tag-spec>.made;
            my $body-ast = $d<tag-body>;
            $ast.push: { :$tag-ast, :$body-ast, :doc-ast($d.made)};
          }
        }
      }
    }

    # Set AST on node tag-body
    $match.make($ast);
  }

#`{{
  #-----------------------------------------------------------------------------
  method attr-value-spec ( Match $match ) {
    note $match.Str;
  }
}}
#`{{
  #-----------------------------------------------------------------------------
  method comment ( Match $match ) {
    dump $match;
  }
}}

  #-----------------------------------------------------------------------------
  # Return object if module and method is found. Otherwise return Any
  method !can-method ( Str $mod-name, $meth-name, Bool :$optional = True ) {

    my XML::Element $x;

    my $module = $!objects{$mod-name} if $!objects{$mod-name}:exists;

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

  #-----------------------------------------------------------------------------
  method !clean-text (
    Str $t is copy, Bool :$fixed = False, Bool :$comment = True
    --> Str
  ) {

    # filter comments
    $t ~~ s:g/ <.ws> '#' \N* \n // if $comment;
    $t ~~ s:g/^ '#' \N* \n // if $comment;

    # remove leading spaces at begin of text
    $t ~~ s/^ \s+ // unless $fixed;

    # remove trailing spaces at every line
    $t ~~ s:g/ \h+ $$ //;

    # substitute multiple spaces with one space
    $t ~~ s:g/ \s\s+ / / unless $fixed;

    # remove return characters if found
    $t ~~ s:g/ \n+ / / unless $fixed;

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

    $t;
  }

  #-----------------------------------------------------------------------------
  # Substitute some escape characters in entities and remove the remaining
  # backslashes.
  #
  method !process-esc ( Str $esc is copy --> Str ) {

    # Entity must be known in the xml result!
    $esc ~~ s:g/\& <!before '#'? \w+ ';'>/\&amp;/;
    $esc ~~ s:g/\\\s/\&nbsp;/;
    $esc ~~ s:g/ '<' /\&lt;/;
    $esc ~~ s:g/ '>' /\&gt;/;

    $esc ~~ s:g/'\\'//;

#`{{
    # Remove rest of the backslashes unless followed by hex numbers prefixed
    # by an 'x'
    #
    if $esc ~~ m/ '\\x' <xdigit>+ / {
      my $set-utf8 = sub ( $m1, $m2) {
        return Blob.new( :16($m1.Str), :16($m2.Str)).decode;
      };

      $esc ~~ s:g/ '\\x' (<xdigit>**2) (<xdigit>**2) /{&$set-utf8( $0, $1)}/;
    }
}}

    return $esc;
  }

  #-----------------------------------------------------------------------------
  method !current-state ( Match $match, Str $state ) {

    $!from = $match.from;
    $!to = $match.to;
    $!prematch = $match.prematch;
    $!postmatch = $match.postmatch;
    $!state = $state;
  }

  #-----------------------------------------------------------------------------
  method Xset-objects( Hash:D $objects ) {

    $!objects = $objects;
  }

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

  #-----------------------------------------------------------------------------
  method get-document ( --> XML::Document ) {

    return $!xml-document;
  }
}
