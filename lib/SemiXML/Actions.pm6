use v6.c;
use XML;

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

    has Hash $.symbols = {};

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

    # Objects hash with one predefined object for core methods
    #
    has Hash $.objects = { SxmlCore => SemiXML::SxmlCore.new() };
    has Hash $.config is rw = {};
    has XML::Document $!xml-document;

     # Keep current state of affairs. Hopefully some info when parsing fails
     has Int $.from;
     has Int $.to;
     has Str $.prematch;
     has Str $.postmatch;
     has Str $.state;

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

      my $parent = $match<document>.ast;

      # Cleanup residue tags left from processing methods. The childnodes in
      #'__PARENT_CONTAINER__' tags must be moved to the parent of it. There
      # is one exception, that is when the tag is at the top. Then there may
      # only be one tag. If there are more, an error tag is generated.
      #
      my $containers = $parent.getElementsByTagName('__PARENT_CONTAINER__');
      for @$containers -> $node {

        my $children = $node.nodes;

        # Eat from the end of the list and add just after the container element.
        # Somehow they get lost from the array when done otherwise.
        #
        for @$children.reverse {
          $node.parent.after( $node, $^a);
        }

        $node.parent.removeChild($node);
      }

      # Process top level method container
      if $parent.name() eq '__PARENT_CONTAINER__' {
        if $parent.nodes == 1 {
          $parent = $parent.nodes[0];
        }

        else {
          my $tag-ast = $match<document><tag-spec>.ast;
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
          $x.set( $k, self!process-esc($v));
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

      $after-math($parent);

      # Return the completed report
      $!xml-document .= new($parent);
    }

    #---------------------------------------------------------------------------
    method document ( $match ) {

      self!current-state( $match, 'document');

      my XML::Element $x;

      ( my $tt,                 # tag type
        my $ns, my $tn,         # namespace and tag name
        my $mod, my $symmth,    # module and symbol or method
        my $att                 # attributes
      ) = @($match<tag-spec>.ast);

      # Check the node type
      given $tt {

        # Any normal tag
        when any(< $ $** $*| $|* >) {

          my Str $tag = (?$ns ?? "$ns:" !! '') ~ $tn;

          $x .= new( :name($tag), :attribs(%$att));
        }

        # Substitution tag
        when '$.' {

          my $module = $!objects{$mod} if $!objects{$mod}:exists;

          # Check if module exists
          if $module.defined {

            # Test if symbols accessor exists in module
            if $module.^can('symbols') {
              my Str $tn = $!objects{$mod}.symbols{$symmth}<tag-name>;
              my Hash $at = $!objects{$mod}.symbols{$symmth}<attributes> // {};
              $x .= new( :name($tn), :attribs( |%$at, |%$att));
            }

            else {
              $x .= new(
                :name('undefined-method'),
                :attribs( module => $mod, :method<symbols>)
              );
            }
          }

          else {
            $x .= new(
              :name('undefined-module'),
              :attribs(module => $mod)
            );
          }
        }

        # Method tag
        when '$!' {

          # Get the module if it exists
          my $module = $!objects{$mod} if $!objects{$mod}:exists;

          # check it
          if $module.defined {

            # test if symbols accessor exists in module
            if $module.^can($symmth) {

              # call user method and expect result in $x
              $x = $module."$symmth"(
                XML::Element.new(:name('__PARENT_CONTAINER__')),
                $att,
                :content-body( self!build-content-body(
                    $match<tag-body>.ast,
                    XML::Element.new(:name('__BODY_CONTAINER__'))
                  )
                )
              );

              if not $x.defined {
                $x .= new(
                  :name('method-returned-no-result'),
                  :attribs( module => $mod, method => $symmth)
                );
              }
            }

            else {
              $x .= new(
                :name('undefined-method'),
                :attribs( module => $mod, method => $symmth)
              );
            }
          }

          else {
            $x .= new( :name('undefined-module'), :attribs(module => $mod));
          }
        }
      }

      # For all types but methods
      if $tt ~~ any(< $ $** $*| $|* $. >) {

        # Check for xmlns uri definitions and set them on the current node
        for $att.keys {
          when m/^ 'xmlns:' ( <before '='>* ) $/ {
            my $ns-prefix = $0;
            $x.setNamespace( $att{$_}, $0);
          }
        }

        self!build-content-body( $match<tag-body>.ast, $x);
      }

      # Set AST on node document
      $match.make($x);
    }

    #---------------------------------------------------------------------------
    method !build-content-body (
      $ast, XML::Element $parent

      --> XML::Element
    ) {

      for @$ast {
        # Any piece of found text
        when Str {
          $parent.append(SemiXML::Text.new(:text($_))) if ?$_;
        }

        # Nested document: [ tag ast, body ast, doc xml]
        when Array {

          # tag ast: [ tag type, namespace, tag name, module, method, attributes
          my Array $tag-ast = $_[0];

          # Test if spaces are needed before the document
          $parent.append(SemiXML::Text.new(:text(' ')))
            if $tag-ast[0] ~~ any(< $** $*| >);

          $parent.append($_[2]);

          # Test if spaces are needed after the document
          $parent.append(SemiXML::Text.new(:text(' ')))
            if $tag-ast[0] ~~ any(< $** $|* >);
        }
      }

      $parent;
    }

    #---------------------------------------------------------------------------
    method tag-spec ( $match ) {

      self!current-state( $match, 'tag specification');

      my Array $ast = [];

      my Str $symbol = $match<tag><sym>.Str;
      $ast.push: $symbol;

      if $symbol ~~ any(< $** $|* $*| $ >) {

        my $tn = $match<tag><tag-name>;
        $ast.push: ($tn<namespace> // '').Str, $tn<element>.Str, '', '';
      }

      elsif $symbol eq '$.' {

        my $tn = $match<tag>;
        $ast.push: '', '', $tn<mod-name>.Str, $tn<sym-name>.Str;
      }

      elsif $symbol eq '$!' {

        my $tn = $match<tag>;
        $ast.push: '', '', $tn<mod-name>.Str, $tn<meth-name>.Str;
      }

      my Hash $attrs = {};
      for $match<attributes>.caps -> $as {
        next unless $as<attribute>:exists;
        my $a = $as<attribute>;
        my $av = $a<attr-value-spec><attr-value>.Str;
        $attrs{$a<attr-key>.Str} = $av;
      }

      $ast.push: $attrs;

      # Set AST on node tag-name
      $match.make($ast);
    }

    #---------------------------------------------------------------------------
    method tag-body ( $match ) {

      self!current-state( $match, 'tag body');
      my Array $ast = [];
      for $match.caps {

        my $p = $^a.key;
        my $v = $^a.value;

        # Text cannot have nested documents and text must be taken literally
        if $p eq 'body1-contents' {

          $ast.push: self!clean-text( $v<body2-text>.Str, :fixed);
        }

        # Text cannot have nested documents and text may be re-formatted
        elsif $p eq 'body2-contents' {

          $ast.push: self!clean-text( $v<body2-text>.Str, :!fixed);
        }

        # Text can have nested documents and text must be taken literally
        if $p eq 'body3-contents' {

          for $match<body3-contents>.caps {

            my $p3 = $^a.key;
            my $v3 = $^a.value;

            if $p3 eq 'body1-text' {

              $ast.push: self!clean-text( $v3.Str, :fixed);
            }

            # Text cannot have nested documents and text may be re-formatted
            elsif $p3 eq 'document' {

              my $d = $v3;
              my $tag-ast = $d<tag-spec>.ast;
              my $body-ast = $d<tag-body>.ast;
              $ast.push([ $tag-ast, $body-ast, $d.ast]);
            }
          }
        }

        # Text can have nested documents and text may be re-formatted
        elsif $p eq 'body4-contents' {

          for $match<body4-contents>.caps {

            my $p4 = $^a.key;
            my $v4 = $^a.value;

            if $p4 eq 'body1-text' {

              $ast.push: self!clean-text( $v4.Str, :!fixed);
            }

            # Text cannot have nested documents and text may be re-formatted
            elsif $p4 eq 'document' {

              my $d = $v4;
              my $tag-ast = $d<tag-spec>.ast;
              my $body-ast = $d<tag-body>.ast;
              $ast.push([ $tag-ast, $body-ast, $d.ast]);
            }
          }
        }
      }

      # Set AST on node tag-body
      $match.make($ast);
    }

    #---------------------------------------------------------------------------
    method !clean-text ( Str $t is copy, Bool :$fixed = False --> Str ) {

      # Remove leading spaces at begin of text
      $t ~~ s/^ \s+ // unless $fixed;

      # Remove trailing spaces at every line
      $t ~~ s:g/ \h+ $$ //;

      # Substitute many spaces with one space
      $t ~~ s:g/ \s\s+ / / unless $fixed;

      $t;
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
    # Substitute some escape characters in entities and remove the remaining
    # backslashes.
    #
    method !process-esc ( Str $esc is copy --> Str ) {

      # Entity must be known in the xml result!
      #
      $esc ~~ s:g/\\\\/\&\#x5C;/;
      $esc ~~ s:g/\\\s/\&nbsp;/;
      $esc ~~ s:g/\</\&lt;/;
      $esc ~~ s:g/\>/\&gt;/;
      $esc ~~ s:g/\"/\&quot;/;

      # Remove rest of the backslashes unless followed by hex numbers prefixed
      # by an 'x'
      #
      if $esc ~~ m/ '\\x' <xdigit>+ / {
        my $set-utf8 = sub ( $m1, $m2) {
          return Blob.new(:16($m1.Str),:16($m2.Str)).decode;
        };

        $esc ~~ s:g/ '\\x' (<xdigit>**2) (<xdigit>**2) /{&$set-utf8( $0, $1)}/;
      }

      if $esc ~~ m/ '\\u' <xdigit>+ / {
        my $set-utf8 = sub ($m1) {

          return chr(:16($m1.Str));
        };
        $esc ~~ s:g/ '\\u' (<xdigit>**4) /{&$set-utf8($0)}/;
      }

      $esc ~~ s:g/\\//;

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
    method get-document ( --> XML::Document ) {
      return $!xml-document;
    }
  }
}



