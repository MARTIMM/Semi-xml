use v6.c;
use XML;

#use Data::Dump::Tree;

package SemiXML:auth<https://github.com/MARTIMM> {

  #-----------------------------------------------------------------------------
  # Must make this class to substitute on XML::Text. That class removes all
  # spaces at the start and end of the content and removes newlines too
  # This is bad for tags like HTML <pre> and friends. With this class stripping
  # can be controlled better.
  #
  class Text does XML::Node {

    has Bool $.strip;
    has Str $.txt;

    method Str ( ) {
      return $!txt;
    }

    submethod BUILD ( Bool :$strip = False, Str :$text ) {

      $!strip = $strip;
      $!txt = $text;

      if $strip {
        $!txt ~~ s:g/\s+$$//;   ## Chop out trailing spaces from lines.
        $!txt ~~ s:g/^^\s+//;   ## Chop out leading spaces from lines.
        $!txt .= chomp;         ## Remove a trailing newline if it exists.
      }
    }
  }

  #-----------------------------------------------------------------------------
  # Core module with common used methods
  #
  class SxmlCore {

    # $!SxmlCore.date year=nn month=nn day=nn []
    #
    method date ( XML::Element $parent,
                  Hash $attrs,
                  XML::Node :$content-body   # Ignored
                ) {

#      $parent.append(XML::Text.new(:text(Date.today().Str)));
      $parent.append(XML::Text.new(:text(' ')));

      my Int $year = +$attrs<year> if ? $attrs<year>;
      my Int $month = +$attrs<month> if ? $attrs<month>;
      my Int $day = +$attrs<day> if ? $attrs<day>;

      if ? $year and ? $month and ? $day {
        $parent.append(
          XML::Text.new(
            :text(Date.new( $year, $month, $day).Str)
          )
        );
      }

      elsif ? $year {
        if ? $month and ? $day {
          $parent.append(
            XML::Text.new(
              :text(Date.new( :$year, :$month, :$day).Str)
            )
          );
        }

        elsif ? $month {
          $parent.append(
            XML::Text.new(
              :text(Date.new( :$year, :$month).Str)
            )
          );
        }

        elsif ? $day {
          $parent.append(
            XML::Text.new(
              :text(Date.new( :$year, :$day).Str)
            )
          );
        }

        else {
          $parent.append(
            XML::Text.new(
              :text(Date.new(:$year).Str)
            )
          );
        }
      }

      else {
        $parent.append(
          XML::Text.new(
            :text(Date.today().Str)
          )
        );
      }

      $parent;
    }

    # $!SxmlCore.date-time timezone=tz iso=n []
    #
    method date-time ( XML::Element $parent,
                       Hash $attrs,
                       XML::Node :$content-body   # Ignored
                     ) {

#      my $date-time = DateTime.now().Str;
      my $date-time;

      if $attrs<timezone> {
        $date-time = DateTime.now(:timezone($attrs<timezone>.Int)).Str;
      }

      else {
        $date-time = DateTime.now().Str;
      }

      $date-time ~~ s/'T'/ / unless $attrs<iso>:exists;
      $date-time ~~ s/'+'/ +/ unless $attrs<iso>:exists;
#      my $txt-e = XML::Text.new(:text($date-time));
#      $parent.append($txt-e);
      $parent.append(XML::Text.new(:text($date-time)));
      $parent;
    }

    # $!SxmlCore.comment []
    #
    method comment ( XML::Element $parent,
                     Hash $attrs,
                     XML::Node :$content-body
                   ) {

      # Textify all body content
      my Str $comment-content = [~] $content-body.nodes;

      # Remove textitified container tags from the text
      $comment-content ~~ s:g/ '<' '/'? '__PARENT_CONTAINER__>' //;

      $parent.append(XML::Comment.new(:data($comment-content)));
      $parent;
    }

    # $!SxmlCore.cdata []
    #
    method cdata ( XML::Element $parent,
                   Hash $attrs,
                   XML::Node :$content-body
                 ) {

      # Textify all body content
      my Str $cdata-content = [~] $content-body.nodes;

      # Remove textitified container tags from the text
      $cdata-content ~~ s:g/ '<' '/'? '__PARENT_CONTAINER__>' //;

      $parent.append(XML::CDATA.new(:data($cdata-content)));
      $parent;
    }

    # $!SxmlCore.pi []
    #
    method pi ( XML::Element $parent,
                Hash $attrs,
                XML::Node :$content-body
              ) {
      $parent.append(XML::PI.new(:data([~] $content-body.nodes)));
      $parent;
    }
  }

  #-----------------------------------------------------------------------------
#TODO comments
  class Actions {

    # Caller SemiXML::Sxml object
    has $!sxml-obj;

    # Objects hash with one predefined object for core methods
    has Hash $.objects = { SxmlCore => SemiXML::SxmlCore.new() };
    has Hash $.config is rw = {};
    has XML::Document $!xml-document;

    # Keep current state of affairs. Hopefully some info when parsing fails
    has Int $.from;
    has Int $.to;
    has Str $.prematch;
    has Str $.postmatch;
    has Str $.state;

    has Array $.unleveled-brackets = [];

    # Save a list of tags from root to deepest level. This is possible because
    # body is processed later than tag-spec. The names are the element name,
    # method name or symbol name. The xml namesspace and module name are not
    # added because these can be any name defined by the user.
    #
    has Array $!tag-list = [];

    #---------------------------------------------------------------------------
    submethod BUILD ( :$sxml-obj ) {
      $!sxml-obj = $sxml-obj;
    }

    #---------------------------------------------------------------------------
    method init-doc ( $match ) {

      self!current-state( $match, 'initializing doc');
      state $init-to-fail =
        XML::Element.new(:name<failed-to-parse-sxml-document>);
      $!xml-document .= new($init-to-fail);
    }

    #---------------------------------------------------------------------------
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

        # Eat from the end of the list and add just after the container element.
        # Somehow they get lost from the array when done otherwise.
        #
        for @$children.reverse {
          $node.parent.after( $node, $^a);
        }

        # Remove the now empty element
        $node.remove;
      }

      # Process top level method container
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

      # Conversion to xml escapes is done as late as possible
      my Sub $after-math = sub ( XML::Element $x ) {

        # Process attributes to escape special chars
        my %a = $x.attribs;
        for %a.kv -> $k, $v {
          $x.set( $k, self!process-esc( $v, :is-attr));
        }

        # Process body text to escape special chars
        for $x.nodes -> $node {
          if $node ~~ any( SemiXML::Text, XML::Text) {
            my Str $s = self!process-esc(~$node);
            $node.parent.replace( $node, SemiXML::Text.new(:text($s)));
          }

          elsif $node ~~ XML::Element {
            $after-math($node);
          }
        }
      }

      &$after-math($parent);

      # Return the completed report
      $!xml-document .= new($parent);
    }

    #---------------------------------------------------------------------------
    method pop-tag-from-list ( $match ) {

#TODO only after the last block. Also when no block is found!
      # This level is done so drop an element tag from the list
      $!tag-list.pop;
    }

    #---------------------------------------------------------------------------
    method document ( $match ) {

#dump $match;
      # Try to find indent level to match up open '[' with close ']'.
      #
      # 1) $|x                  no body at all
      # 2) $|x [ ]              no newline in body
      # 3) $|x [                with newline, the ']' should line up with $|x.
      #    ]
      # 4) $|x [ ] [ ]          multiple bodies no newline
      # 5) $|x [                idem with newline in first body. 1st ']'
      #    ] [                  lines up with $|x. When in 2nd, the 2nd ']'
      #    ]                    should also line up with $|x
      # 6) $|x [ $|y [ ] ]      nested bodies no newline
      # 7) $|x [                with newline, outer ']' should line up
      #      $|y [              with $|x and inner ']' with $|y.
      #      ]
      #    ]
      #
      my Str $orig = $match.orig;
      my Int $from = $match.from;
      my Int $to = $match.to;

#say "ORDoc:  $from, $to: $orig";

      my Array $tag-bodies = $match<tag-body>;
      loop ( my $mi = 0; $mi < $tag-bodies.elems; $mi++ ) {

        my Int $b-from = $match.from;
        my Int $b-to = $match.to;
#say "ORBody $b-from, $b-to";

        # find start of body
        my Int $bstart = $match.orig.substr( $b-from, $b-to - $b-from).index('[')
                       + $b-from;

        # find end of body, search from the end
        my Int $bend = $match.orig.substr( $bstart, $b-to - $bstart).rindex(']')
                     + $bstart;

        # check for newlines in this body
        my Bool $has-nl = (
          $match.orig.substr( $bstart, $bend - $bstart).index("\n")
        ).defined;

#say "BE: $bstart, $bend, $has-nl";
        # if there is a newline, check alignment
        if $has-nl {

          my Int $tag-loc = $match<tag-spec>.from;
          my Int $indent-start = $tag-loc
                        - ($orig.substr( 0, $tag-loc).rindex("\n") // -1) - 1;

          my Int $indent-end = $bend
                        - ($orig.substr( 0, $bend).rindex("\n") // -1) - 1;
#say "NLDoc  $tag-loc, $indent-start, $indent-end, $bstart, $bend";

          # make a note when indents are not the same, it might point to a
          # missing bracket.
          if $indent-start != $indent-end {

            $match.prematch.Str ~~ m:g/ (\n) /;
            my $line-number = $/.elems + 1;
            $!unleveled-brackets.push: {
              tag-name => $match<tag-spec><tag>.Str,
              :$line-number,
              body-count => $mi + 1
            };
#dump $!unleveled-brackets;
          }
        }
      }

      self!current-state( $match, 'document');

      my XML::Element $x;

      ( my $tt,                 # tag type
        my $ns, my $tn,         # namespace and tag name
        my $mod, my $meth,      # module and method
        my $att                 # attributes
      ) = @($match<tag-spec>.made);

      # Check the node type
      given $tt {

        # Any normal tag
        when any(< $| $** $*| $|* >) {

          my Str $tag = (?$ns ?? "$ns:" !! '') ~ $tn;

          $x .= new( :name($tag), :attribs(%$att));

          # Check for xmlns uri definitions and set them on the current node
          for $att.keys {
            when m/^ 'xmlns:' ( <before '='>* ) $/ {
              my $ns-prefix = $0;
              $x.setNamespace( $att{$_}, $0);
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

            # call user method and expect result in $x
            $x = $module."$meth"(
              XML::Element.new(:name('__PARENT_CONTAINER__')),
              $att,
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

    #---------------------------------------------------------------------------
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
            if ? $$txt {
              $parent.append(SemiXML::Text.new(:text(' '))) if $mi;
              $parent.append(SemiXML::Text.new(:text($$txt)));
            }
          }

          # Nested document: Ast holds { :tag-ast, :body-ast, :doc-ast}
          when Hash {
#say "Ast hash: ", $_.keys;
#say "Ast tag: ", $_<tag-ast>;
#say "Ast body: ", $_<body-ast>;
#say "Ast doc: ", $_<doc-ast>;
            # tag ast: [ tag type, namespace, tag name, module, method, attributes
            my Array $tag-ast = $_<tag-ast>;

            # Test if spaces are needed before the document
            $parent.append(SemiXML::Text.new(:text(' ')))
              if $tag-ast[0] ~~ any(< $** $*| >);

            $parent.append($_<doc-ast>);

            # Test if spaces are needed after the document
            $parent.append(SemiXML::Text.new(:text(' ')))
              if $tag-ast[0] ~~ any(< $** $|* >);
          }
        }
      }

      $parent;
    }

    #---------------------------------------------------------------------------
    method tag-spec ( $match ) {

#say ~$match;

      self!current-state( $match, 'tag specification');

      # Name of element or method to be saved in array $!tag-list on $!level
      my Str $tag-name;

      my Array $ast = [];

      my Str $symbol = $match<tag><sym>.Str;
      $ast.push: $symbol;
#say "Tag symbol: $symbol";
#dump $match;

      # find level of indent

      my Hash $attrs = {};
      for $match<attributes>.caps -> $as {
        next unless $as<attribute>:exists;
        my $a = $as<attribute>;
        my $av = $a<attr-value-spec><attr-value>.Str;
        $attrs{$a<attr-key>.Str} = $av;
      }

      if $symbol ~~ any(< $** $|* $*| $| >) {

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
        $module.initialize( $!sxml-obj, $attrs) if $module;
      }

      # Add to the list
      $!tag-list.push($tag-name);
#say "Tag name: $tag-name";

      $ast.push: $attrs;

      # Set AST on node tag-name
      $match.make($ast);
    }

    #---------------------------------------------------------------------------
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

    #---------------------------------------------------------------------------
#    method comment ( Match $match ) {
#      say "Comment: ", $match.perl;
#      $match.make: (:comment($match.Str));
#      $match.make: [comment => ~$match];
#    }

    #---------------------------------------------------------------------------
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

    #---------------------------------------------------------------------------
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

      $t;
    }

    #---------------------------------------------------------------------------
    # Substitute some escape characters in entities and remove the remaining
    # backslashes.
    #
    method !process-esc ( Str $esc is copy, Bool :$is-attr = False --> Str ) {

      # Entity must be known in the xml result!
      $esc ~~ s:g/\& <!before '#'? \w+ ';'>/\&amp;/ unless $is-attr;
      $esc ~~ s:g/\\\s/\&nbsp;/ unless $is-attr;
      $esc ~~ s:g/\</\&lt;/ unless $is-attr;

      $esc ~~ s:g/\"/\&quot;/ if $is-attr;
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

    #---------------------------------------------------------------------------
    method !current-state ( Match $match, Str $state ) {

      $!from = $match.from;
      $!to = $match.to;
      $!prematch = $match.prematch;
      $!postmatch = $match.postmatch;
      $!state = $state;
    }

    #---------------------------------------------------------------------------
    method process-config-for-modules ( ) {

      if $!config<module>:exists {
        for $!config<module>.kv -> $key, $value {
          if $!objects{$key}:!exists {
            if $!config<library>{$key}:exists {

              my $repository = CompUnit::Repository::FileSystem.new(
                :prefix($!config<library>{$key})
              );
              CompUnit::RepositoryRegistry.use-repository($repository);
            }

            require ::($value);
            my $obj = ::($value).new;
            $!objects{$key} = $obj;
          }
        }
      }
    }

    #---------------------------------------------------------------------------
    method get-current-filename ( --> Str ) {

      return $!config<output><filepath> ~ '/' ~ $!config<output><filename>;
    }

    #---------------------------------------------------------------------------
    method get-document ( --> XML::Document ) {

      return $!xml-document;
    }

    #---------------------------------------------------------------------------
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
  }
}



