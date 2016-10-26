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

    # $!SxmlCore.date []
    #
    method date ( XML::Element $parent,
                  Hash $attrs,
                  XML::Node :$content-body   # Ignored
                ) {

      $parent.append(XML::Text.new(:text(Date.today().Str)));
    }

    # $!SxmlCore.date-time []
    #
    method date-time ( XML::Element $parent,
                       Hash $attrs,
                       XML::Node :$content-body   # Ignored
                     ) {

      my $date-time = DateTime.now().Str;
      $date-time ~~ s/'T'/ / unless $attrs<iso>:exists;
      $date-time ~~ s/'+'/ +/ unless $attrs<iso>:exists;
      my $txt-e = XML::Text.new(:text($date-time));
      $parent.append($txt-e);
    }

    # $!SxmlCore.comment []
    #
    method comment ( XML::Element $parent,
                     Hash $attrs,
                     XML::Node :$content-body
                   ) {
      $parent.append(XML::Comment.new(:data([~] $content-body.nodes)));
    }

    # $!SxmlCore.cdata []
    #
    method cdata ( XML::Element $parent,
                   Hash $attrs,
                   XML::Node :$content-body
                 ) {
      $parent.append(XML::CDATA.new(:data([~] $content-body.nodes)));
    }

    # $!SxmlCore.pi []
    #
    method pi ( XML::Element $parent,
                Hash $attrs,
                XML::Node :$content-body
              ) {
      $parent.append(XML::PI.new(:data([~] $content-body.nodes)));
    }
  }

  #-----------------------------------------------------------------------------
  class Actions {
#    our $debug = False;

    # Objects hash with one predefined object for core methods
    #
    has Hash $.objects = { SxmlCore => SemiXML::SxmlCore.new() };
#TODO check out
    has Hash $.config is rw = {};
#    has Hash $.config = {};
#    has Hash $config-key = {};
#    has Str $!config-path;
#    has Str $!config-value;

    has XML::Document $!xml-document;
#    has Int $!current-el-idx;
#    has Array $!el-stack;
#    has Array $!deferred-calls;
#    has Array $!el-keep-literal;

#    has Str $!tag-name;
#    has Str $!tag-type;

#    has Hash $!attrs;
#    has Str $!attr-key;

#    has Bool $!keep-literal;
#    has Bool $!has-comment;

     # Keep current state of affairs. Hopefully some info when parsing fails
     has Int $.from;
     has Int $.to;
     has Str $.prematch;
     has Str $.postmatch;
     has Str $.state;

#`{{
    # Initialize some variables when init is set. Must be done when a new object
    # is created: the variables are 'seen' in the other object
    #
    submethod BUILD ( ) {
      $!current-el-idx = Int;
      $!el-stack = [];
      $!deferred-calls = [];
      $!has-comment = False;
    }
}}

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
#say "\nTOP: $parent.name(), ", $parent;

      # Cleanup residue tags left from processing methods. The childnodes in
      #'__PARENT_CONTAINER__' tags must be moved to the parent of it. There
      # is one exception, that is when the tag is at the top. Then there may
      # only be one tag. If there are more, an error tag is generated.
      #
      my $containers = $parent.getElementsByTagName('__PARENT_CONTAINER__');
      for @$containers -> $node {

        my $children = $node.nodes;
#say "C: $children.join(',')";

        # Eat from the end of the list and add just after the container element.
        # Somehow they get lost from the array when done otherwise.
        #
        for @$children.reverse {
          $node.parent.after( $node, $^a);
        }

        $node.parent.removeChild($node);
      }

      # Process top level metod container
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
  say $s;
            $node.parent.replace( $node, SemiXML::Text.new(:text($s)));
          }

          elsif $node ~~ XML::Element {
            $after-math($node);
          }
        }
      }

      $after-math($parent);



      $!xml-document .= new($parent);
    }

#`{{
    #-----------------------------------------------------------------------------
    # All config entries are like: '/a/b/c: v;' This must be evaluated as
    # "$!config<$!config-path>='$!config-value'" so it becomes a key value pair
    # in the config.
    #
    method config-entry ( $match ) {
      if $!config-path.defined and $!config-value.defined {

        # Remove first character if /
        #
        $!config-path ~~ s/^\///;
        my $cp = $!config-path;

        my @paths = $!config-path.split('/');
        my $cf := $!config;
        for @paths -> $p {
          $cf := $cf{$p};
        }

        $cf = $!config-value;
      }
    }

    method config-keypath ( $match ) { $!config-path = ~$match; }
    method config-value ( $match )   { $!config-value = ~$match; }
}}

#`{{
    # After all of the prelude is stored, check if the 'module' keyword is used.
    # If so, evaluate the module and save the created object in $!objects. E.g.
    # suppose a config 'module/file: Sxml::Lib::File;' is used then the object
    # created from that module call '$obj = Sxml::Lib::File.new();' and is stored
    # like '$!objects<file> = $obj;'. A library path is used when config key
    # 'library/file: path/to/mod' is used in previous example.
    #
    method prelude ( $match ) {

      if $!config<option><debug>:exists and ?$!config<option><debug> {
        say "\nTurn debugging on\n";
        $debug = True;
      }

      if $!config<module>:exists {
        for $!config<module>.kv -> $key, $value {
          if $!objects{$key}:exists {
            say "'module/$key:  $value;' found before, ignored";
          }

          else {
#`{ {
            my $use-lib = '';
            if $!config<library>{$key}:exists {
              $use-lib = "\nuse lib '$!config<library>{$key}';";
            }

            my $obj;

            my $code = qq:to/EOCODE/;
              use v6.c;$use-lib
              use $value;
              \$obj = $value.new;
            EOCODE
#say "\n$code\n";
            EVAL($code);
            if $! {
              say "Eval error:\n$!\n";
            }

            else {
              $!objects{$key} = $obj;
            }
} }
#say "use lib $!config<library>{$key}" if $!config<library>{$key}:exists;
#say "require ::($value)";
            if $!config<library>{$key}:exists {
              my $repository = CompUnit::Repository::FileSystem.new(
                :prefix($!config<library>{$key})
              );
              CompUnit::RepositoryRegistry.use-repository($repository);
            }

            require ::($value);
            my $obj = ::($value).new;
            $!objects{$key} = $obj;
#say "Obj methods: ", $obj.^methods;
          }
        }
      }
    }
}}

#`{{
    method tag-type ( $match ) {
      $!tag-type = ~$match;
    }

    method tag-name ( $match ) {
      # Initialize on start of a new tag. Everything of any previous tag is
      # handled and stored.
      #
      $!attr-key = Str;
      $!attrs = {};

      $!tag-name = ~$match;
    }
}}

    #-----------------------------------------------------------------------------
    method document ( $match ) {

      self!current-state( $match, 'document');

#say "Doc tag: " ~ $match<tag-spec>;
      my XML::Element $x;

      ( my $tt,                 # tag type
        my $ns, my $tn,         # namespace and tag name
        my $mod, my $symmth,    # module and symbol or method
        my $att                 # attributes
      ) = @($match<tag-spec>.ast);
#say "Array: $tt, $ns, $tn, $mod, $symmth, {$att.kv ==> map { [~] $^a, ' => ', $^b, ', ' }}";

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

          my $module = $!objects{$mod} if $!objects{$mod}:exists;

          # check if module exists
          if $module.defined {

            # test if symbols accessor exists in module
            if $module.^can($symmth) {

              # call user method and expect result in $y
              $x = $module."$symmth"(
                XML::Element.new(:name('__PARENT_CONTAINER__')),
                $att,
                :content-body( self!build-content-body(
                    $match<tag-body>.ast,
                    XML::Element.new(:name('__BODY_CONTAINER__'))
                  )
                )
              );
#say "X: $x, ", $x.nodes;

#`{{
              # move all child nodes of $y to $x
              if $y.defined {
say "Y: $y, ", $y.nodes;
                $x.append($_) for $y.nodes;
                undefine $y;
              }
}}
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
            $x .= new(
              :name('undefined-module'),
              :attribs(module => $mod)
            );
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

#say 'xml: ', $x;


      # Set AST on node document
      $match.make($x);
    }

    #-----------------------------------------------------------------------------
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

#          if $tag-ast[0] eq '$!' {
#            $parent.append($_) for $tag-ast[2].nodes;
#            $tag-ast[2].remove;
#          }

#          else {
            $parent.append($_[2]);
#          }

          # Test if spaces are needed after the document
          $parent.append(SemiXML::Text.new(:text(' ')))
            if $tag-ast[0] ~~ any(< $** $|* >);
        }
      }

      $parent;
    }

    #-----------------------------------------------------------------------------
    method tag-spec ( $match ) {

      self!current-state( $match, 'tag specification');
#      say 'T0: ', $match<tag>;
#      say 'T1: ', $match<attributes>;
#      say 'T2: ', $match<attributes>.elems;

      my Array $ast = [];

      my Str $symbol = $match<tag><sym>.Str;
      $ast.push: $symbol;
#say "type: $symbol";

      if $symbol ~~ any(< $** $|* $*| $ >) {

        my $tn = $match<tag><tag-name>;
#say 'name: ' ~ $tn<namespace> if $tn<namespace>:exists;
#say 'element: ' ~ $tn<element>;
        $ast.push: ($tn<namespace> // '').Str, $tn<element>.Str, '', '';
      }

      elsif $symbol eq '$.' {

        my $tn = $match<tag>;
#say 'module name: ' ~ $tn<mod-name>;
#say 'symbol name: ' ~ $tn<sym-name>;
        $ast.push: '', '', $tn<mod-name>.Str, $tn<sym-name>.Str;
      }

      elsif $symbol eq '$!' {

        my $tn = $match<tag>;
#say 'module name: ' ~ $tn<mod-name>;
#say 'method name: ' ~ $tn<meth-name>;
        $ast.push: '', '', $tn<mod-name>.Str, $tn<meth-name>.Str;
      }

      my Hash $attrs = {};
      for $match<attributes>.caps -> $as {
        next unless $as<attribute>:exists;
        my $a = $as<attribute>;
        my $av = $a<attr-value-spec><attr-value>.Str;
#        $av ~~ s:g/\"/\&quot;/;
        $attrs{$a<attr-key>.Str} = $av;
#        $attrs{$a<attr-key>.Str} = self!process-esc($av);
      }

#say 'Attrs: ', $attrs.perl;
      $ast.push: $attrs;

      # Set AST on node tag-name
      $match.make($ast);
    }

    #-----------------------------------------------------------------------------
    method tag-body ( $match ) {

      self!current-state( $match, 'tag body');
#say "M: ", $match;
      my Array $ast = [];
      for $match.caps {

        my $p = $^a.key;
        my $v = $^a.value;
#say "P: ", $p, ' --->> ', ~$v;
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

#say "P b3: ", $p3, ' --->> ', ~$v3;

            if $p3 eq 'body1-text' {
#say "b1txt";

              $ast.push: self!clean-text( $v3.Str, :fixed);
            }

            # Text cannot have nested documents and text may be re-formatted
            elsif $p3 eq 'document' {

              my $d = $v3;
#say "doc: ", $d.ast;
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

#say "P b4: ", $p4, ' --->> ', ~$v4;

            if $p4 eq 'body1-text' {
#say "b1txt";

              $ast.push: self!clean-text( $v4.Str, :!fixed);
            }

            # Text cannot have nested documents and text may be re-formatted
            elsif $p4 eq 'document' {

              my $d = $v4;
#say "doc: ", $d.ast;
              my $tag-ast = $d<tag-spec>.ast;
              my $body-ast = $d<tag-body>.ast;
              $ast.push([ $tag-ast, $body-ast, $d.ast]);
            }
          }
        }
      }

#say "B ast: ", $ast;
      # Set AST on node tag-body
      $match.make($ast);
    }

    #-----------------------------------------------------------------------------
    method !clean-text ( Str $t is copy, Bool :$fixed = False --> Str ) {

      # Remove leading spaces at begin of text
      $t ~~ s/^ \h+ // unless $fixed;

      # Remove trailing spaces at every line
      $t ~~ s:g/ \h+ $$ //;

      # Substitute many spaces with one space
      $t ~~ s:g/ \h\h+ / / unless $fixed;

#      self!process-esc($t) unless $fixed;
      $t;
    }

#`{{
    method attr-key       ( $match ) { $!attr-key = ~$match; }

    method attr-s-value   ( $match ) { self!attr-value(~$match); }
    method attr-q-value   ( $match ) { self!attr-value(~$match); }
    method attr-qq-value  ( $match ) { self!attr-value(~$match); }

    method !attr-value ( $m is copy ) {
      $m ~~ s:g/\"/\&quot;/;
      $!attrs{$!attr-key} = $m;
    }
}}

    # Before the body starts, save the tag name and create the element with
    # its attributes.
    #
#    method reset-keep-literal ( $match )  { $!keep-literal = False; }
#    method keep-literal ( $match )        { $!keep-literal = True; }

#    method body1-start ( $match )         { self!process-tag(); }
#    method body1-text ( $match )          { self!process-text($match); }
#    method body1-end ( $match )           { self!process-body-end(); }

#    method body2-start ( $match )         { self!process-tag(); }
#    method body2-text ( $match )          { self!process-text($match); }
#    method body2-end ( $match )           { self!process-body-end(); }

    # Idea to count lines in the source
    #
#    method ws ( $match ) {
#      ~$match ~~ m:g/(\n)/;
#  say "N-" x $/.elems;
#    }

#    method comment ( $match ) {
#      $!has-comment = True;
#    }

    #-----------------------------------------------------------------------------
    method process-config-for-modules ( ) {

      if $!config<module>:exists {
        for $!config<module>.kv -> $key, $value {
          if $!objects{$key}:exists {
#            say "'module/$key:  $value;' found before, ignored";
          }

          else {

#say "use lib $!config<library>{$key}" if $!config<library>{$key}:exists;
#say "require ::($value)";
            if $!config<library>{$key}:exists {
              my $repository = CompUnit::Repository::FileSystem.new(
                :prefix($!config<library>{$key})
              );
              CompUnit::RepositoryRegistry.use-repository($repository);
            }

            require ::($value);
            my $obj = ::($value).new;
            $!objects{$key} = $obj;
#say "Obj methods: ", $obj.^methods;
          }
        }
      }
    }

#`{{
    #-----------------------------------------------------------------------------
    # Process tags
    method !process-tag ( ) {

say "PT \$.: $!tag-type";

      # Check the tag type
      my $tt = $!tag-type;
      $!tag-name ~~ s/^$tt//;

      # Check substitutable tags starting with $.
      if $!tag-type ~~ m/^'$.'/ {
        # Get modulename
        #
        $!tag-type ~~ m/\$\.(<-[\.]>+)/;
        my $module = $/[0].Str;

say "PT \$.: $!tag-type, $module, $!objects{$module}.symbols.keys()";

        # Test if method exists in module
        if $!objects{$module}.symbols{$!tag-name}:exists {
          my $s = $!objects{$module}.symbols{$!tag-name};
          $!tag-name = $s<tag-name>;

          # Add attribute to existing
          #
          for $s<attributes>.kv -> $k,$v { $!attrs{$k} = $v; }

          # And register element
          #
          self!register-element( $!tag-name, $!attrs);
        }
      }

      # Check method tags starting with $!
      elsif $!tag-type ~~ m/^'$!'/ {

        # Get the module name and remove tag type from tag string to get method
        # Then check existence of method in module.
        #
        $!tag-type ~~ m/\$\!(<-[\.]>+)/;
        my $module = $/[0].Str;
say "Test \$!$module.$!tag-name, ", $!objects{$module}.perl;
        if $!objects{$module}.can($!tag-name) {

          # Must make a copy of the tag-name to a local variable. If tag-name
          # is used directly in the closure, the name is not 'frozen' to the
          # value when the call is defined.. Same goes for attributes.
          #
          my $tgnm = $!tag-name;
          my $mod = $module;
          my $ats = $!attrs;

          # Can happen when top level is already a method
#          $!current-el-idx //= 0;
          my $cei = $!current-el-idx;
say "M: \$!$mod.$tgnm";
say "E: $cei, $!current-el-idx, $!el-stack";
say "\nCan do \$!$mod.$tgnm in element ",
  $cei > 0 ?? $!el-stack[$cei - 1].name !! 'top',
  ', ', $!el-stack[$cei].name;

          $!deferred-calls[$cei] = method ( XML::Node :$content-body ) {
#say "\nCalled \$!$mod.$tgnm";
#say "Parent: $!el-stack[$cei]";
#say "Attrs: $ats";
#say "Content body: ", $content-body.Str;

            $!objects{$mod}."$tgnm"(
              $!el-stack[$cei],         # Parent tag
              $ats,                     # attributes of current tag
              :$content-body            # content of current tag in a
                                        # PLACEHOLDER-ELEMENT tag
            );
          };

          self!register-element( 'PLACEHOLDER-ELEMENT', {});
        }

        else {
          die "No method '$!tag-name' and/or module link '$module' found";
        }
      }

      elsif $!tag-type eq '$*<' {
        self!register-element( $!tag-name, $!attrs, :decorate-left);
      }

      elsif $!tag-type eq '$*>' {
        self!register-element( $!tag-name, $!attrs, :decorate-right);
      }

      elsif $!tag-type eq '$*' {
        self!register-element( $!tag-name, $!attrs, :decorate);
      }

      elsif $!tag-type eq '$' {
#say "Register element: $!tag-name, $!attrs";
        self!register-element( $!tag-name, $!attrs);
      }

      else {

say "Else what?? $*LINE";
      }
    }
}}

#`{{
    #---------------------------------------------------------------------------
    # Create an xml element and add its attributes. When the $!current-el-idx
    # is not yet defined, a new document must be created and pointers initialized.
    # The array is like a stack of elements of which each element is a child
    # of the one before it in the array. The last one in the array is the one  to
    # which text or other elements are appended. In body1-text text elements are
    # appended to this last element When the block is finished (at body1-end) the
    # pointer is moved up to the parent element in the array.
    #
    method !register-element ( Str $tag-name,
                               Hash $attrs,
                               :$decorate = False,
                               :$decorate-left = False,
                               :$decorate-right = False
                             ) {

      # Test if index is defined.
      my $child-element = XML::Element.new( :name($tag-name), :attribs($!attrs));
say "CE: ", $child-element.perl;

      if $!current-el-idx.defined {
        $!el-stack[$!current-el-idx].append(SemiXML::Text.new(:text(' ')))
          if $decorate-left or $decorate;
        $!el-stack[$!current-el-idx].append($child-element);
        $!el-stack[$!current-el-idx].append(SemiXML::Text.new(:text(' ')))
          if $decorate-right or $decorate;
        $!el-stack[$!current-el-idx + 1] = $child-element;

        # Copy current 'keep literal' state.
        $!el-keep-literal[$!current-el-idx + 1] = $!el-keep-literal[$!current-el-idx];

        # Point to the next level in case there is another tag found in the 
        # current body. This element must become the child element of the
        # current one.
        #
        $!current-el-idx++;
      }

      else {

        # First element is a root element
        $!current-el-idx = 0;
        $!el-stack[$!current-el-idx] = $child-element;
        $!el-keep-literal[$!current-el-idx] = False;
        $!xml-document .= new($!el-stack[$!current-el-idx]);
say "CE: ", $!xml-document.perl;
      }
    }
}}

#`{{
    #---------------------------------------------------------------------------
    # Process the text after finding body terminator
    #
    method !process-text ( $match ) {

      # Check if there is a comment found in this text, if so remove it and then
      # modify/remove escape characters
      #
      my $text = ~$match;
#`{ {
      if $!has-comment {
        $text ~~ s:g/ \n \s* '#' <-[\n]>* \n /\n/;
        $!has-comment = False;
      }
} }
      $text = self!process-esc($text);

      my $xml;
#      $!el-keep-literal[$!current-el-idx] ||= $!keep-literal;
      $!el-keep-literal[$!current-el-idx] = False;
      if $!el-keep-literal[$!current-el-idx] {
  #    if $!keep-literal {
  #say "!PRT lit: $!el-keep-literal[$!current-el-idx], {$!el-stack[$!current-el-idx].name}";

  # At the moment too complex to handle removal of a minimal indentation
  if 0 {
  #if $!keep-literal {
  #      $text ~~ s/^\n+//;
  #      $text ~~ s/\s+$//;
  #}


        # Get all spaces at the start of a line
        #
        $text ~~ m:g/^^(\s+)/;
        my @indents = $/[];

        # Then get the length of each whitespace and remember the shortest length
        #
        my $min-spaces = Inf;
        for @indents -> $indent {
          my Str $i = ~$indent;
          $i ~~ s/^\n+//;
          my $nspaces = $i.chars;
          $min-spaces min= $nspaces;
        }

        $text ~~ s:g/^^\s**{$min-spaces}// unless $min-spaces == Inf;
  }
        $xml = SemiXML::Text.new(:text($text)) if $text.chars > 0;
      }

      else {
        $text ~~ s/\s+$//;        ## Chop out trailing spaces from the text.
        $text ~~ s/^\s+//;        ## Chop out leading spaces from the text.
        $xml = SemiXML::Text.new( :text($text), :strip) if $text.chars > 0;
      }

#say "append to $!el-stack[$!current-el-idx]" if $xml.defined;
      $!el-stack[$!current-el-idx].append($xml) if $xml.defined;
#say "appended $!el-stack[$!current-el-idx]" if $xml.defined;
    }
}}

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
#say "m1 & m2: $m1, $m2";
          return Blob.new(:16($m1.Str),:16($m2.Str)).decode;
        };
        $esc ~~ s:g/ '\\x' (<xdigit>**2) (<xdigit>**2) /{&$set-utf8( $0, $1)}/;
      }

      if $esc ~~ m/ '\\u' <xdigit>+ / {
        my $set-utf8 = sub ($m1) {
#say "m1: $m1";
          return chr(:16($m1.Str));
        };
        $esc ~~ s:g/ '\\u' (<xdigit>**4) /{&$set-utf8($0)}/;
      }

      $esc ~~ s:g/\\//;
#say "\n$esc\n\n";
      return $esc;
    }

#`{{
    #---------------------------------------------------------------------------
    # Process body ending
    #
    method !process-body-end ( ) {
      # Go back one level .New child tags will overwrite the previous child
      # on the stack as those are not needed anymore.
      #
      $!current-el-idx--;

      if $!deferred-calls[$!current-el-idx].defined 
         and $!el-stack[$!current-el-idx] ~~ XML::Element
         and $!el-stack[$!current-el-idx + 1].name eq 'PLACEHOLDER-ELEMENT' {
#say "Content of parent: ", $!el-stack[$!current-el-idx + 1].Str;

        # Call the deferred method and pass the element 'PLACEHOLDER-ELEMENT'
        # and all children below it. The method should not remove this element
        # before returning because it will be removed after the call.
        #
        $!deferred-calls[$!current-el-idx](
          self,
          :content-body($!el-stack[$!current-el-idx + 1])
        );
#say "\nEl = $!current-el-idx\n\n", $!el-stack[$!current-el-idx].Str, "\n\n";

        # Remove PLACEHOLDER-ELEMENT if still available
        $!el-stack[$!current-el-idx + 1].remove
          if ?$!el-stack[$!current-el-idx + 1];
      }

      # Call done, now reset
      if $!current-el-idx >= 0 {

        # Remove method from stack
        $!deferred-calls[$!current-el-idx] = Any;

        # Reset the 'keep literal state'
        $!el-keep-literal[$!current-el-idx + 1] = False;
      }
    }
}}

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



