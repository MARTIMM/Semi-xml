use v6;
use XML;

class Semi-xml::Text is XML::Text {
  method Str ( ) {
    return $.text;
  }
}

# Core module with common used methods
#
class Semi-xml::SxmlCore {

  has Hash $.symbols = {};

  # $SxmlCore.date []
  #
  method date ( XML::Element $parent,
                Hash $attrs,
                XML::Node :$content-body   # Ignored
              ) {
    $content-body.remove;

    $parent.append(XML::Text.new(:text(Date.today().Str)));
  }

  # $SxmlCore.date-time []
  #
  method date-time ( XML::Element $parent,
                     Hash $attrs,
                     XML::Node :$content-body   # Ignored
                   ) {
    $content-body.remove;

    my $date-time = DateTime.now().Str;
    $date-time ~~ s/'T'/ / unless $attrs<iso>:exists;
    $date-time ~~ s/'+'/ +/ unless $attrs<iso>:exists;
    my $txt-e = XML::Text.new(:text($date-time));
    $parent.append($txt-e);
  }

  # $SxmlCore.comment []
  #
  method comment ( XML::Element $parent,
                   Hash $attrs,
                   XML::Node :$content-body
                 ) {
    $parent.append(XML::Comment.new(:data([~] $content-body.nodes)));
    $content-body.remove;
  }

  # $SxmlCore.cdata []
  #
  method cdata ( XML::Element $parent,
                 Hash $attrs,
                 XML::Node :$content-body
               ) {
    $parent.append(XML::CDATA.new(:data([~] $content-body.nodes)));
    $content-body.remove;
  }

  # $SxmlCore.pi []
  #
  method pi ( XML::Element $parent,
              Hash $attrs,
              XML::Node :$content-body
            ) {
    $parent.append(XML::PI.new(:data([~] $content-body.nodes)));
    $content-body.remove;
  }
}

class Semi-xml::Actions {
  our $debug = False;


  # Objects hash with one predefined object for core methods
  #
  has Hash $.objects = { SxmlCore => Semi-xml::SxmlCore.new() };
  has Hash $.config = {};

  my Hash $config-key = {};
  my Str $config-path;
  my Str $config-value;

  has XML::Document $.xml-document;
  my Array $el-stack;
  my Int $current-element-idx;
  my Array $deferred-calls;

  my Str $tag-name;
  my Str $tag-type;

  my Hash $attrs;
  my Str $attr-key;

  my Bool $keep-literal = False;

  has Bool $!init;

  submethod BUILD ( Bool :$init ) {
#say "AI: {?$init}";
    if $init {
      $current-element-idx = Int;
      $el-stack = [];
      $deferred-calls = [];
    }
  }

#  has $!deferred-call-idx = -1;
#  has $!content-body = Any;

#  has $!deferred_call = Any;
#  has $!content-text = Any;

  # All config entries are like: '/a/b/c: v;' This must be evauluated as
  # "$!config<$config-path>='$config-value'" so it becomes a key value pair
  # in the config.
  #
  method config-entry ( $match ) {
    if $config-path.defined and $config-value.defined {
      $config-path ~~ s:g/ \/ /\>\</;
      $config-path = "\$!config\<$config-path\>='$config-value'";

      EVAL("$config-path");
    }
  }

  method config-keypath ( $match ) {
    $config-path = ~$match;
  }

  method config-value ( $match ) {
    $config-value = ~$match;
  }

  # After all of the prelude is stored, check if the 'module' keyword is used.
  # If so, evaluate the module and save the created object in $!objects. E.g.
  # suppose a config 'module/file: Sxml::Lib::File;' is used then the object
  # created from that module call '$obj = Sxml::Lib::File.new();' and is stored
  # like '$!objects<file> = $obj;'. A library path is used when config key
  # 'library/file: path/to/mod' is used in previous example.
  #
  method prelude ( $match ) {

#say "D: ", ($debug ?? 'Y' !! 'N');
    if $!config<option><debug>:exists and $!config<option><debug> {
      say "\nTurn debugging on\n";
      $debug = True;
#say "D: ", ($debug ?? 'Y' !! 'N');
    }

    if $!config<module>:exists {
      for $!config<module>.kv -> $key, $value {
        if $!objects{$key}:exists {
          say "'module/$key:  $value;' found before, ignored";
        }

        else {
          my $use-lib = '';
          if $!config<library>{$key}:exists {
            $use-lib = "\nuse lib '$!config<library>{$key}';";
          }

          my $obj;
          my $code = qq:to/EOCODE/;
            use v6;$use-lib
            use $value;
            \$obj = $value.new;

            EOCODE
#say "Code:\n$code\n";
          EVAL($code);
          if $! {
            say "Eval error:\n$!\n";
          }

          else {
            $!objects{$key} = $obj;
          }
        }
      }
    }
  }

  method tag-type ( $match ) {
    $tag-type = ~$match;
#say "TT: '$tag-type'";
  }

  method tag-name ( $match ) {
    # Initialize on start of a new tag. Everything of any previous tag is
    # handled and stored.
    #
    $attr-key = Str;
    $attrs = {};

    $tag-name = ~$match;
#say "TN: '$tag-name'";
  }

  method attr-key       ( $match ) { $attr-key = ~$match; }

  method attr-s-value   ( $match ) { self!attr-value(~$match); }
  method attr-q-value   ( $match ) { self!attr-value(~$match); }
  method attr-qq-value  ( $match ) { self!attr-value(~$match); }

  method !attr-value ( $m is copy ) {
    $m ~~ s:g/\"/\&quot;/;
    $attrs{$attr-key} = $m;
  }

  # Before the body starts, save the tag name and create the element with
  # its attributes.
  #
  method reset-keep-literal ( $match )  { $keep-literal = False; }
  method keep-literal ( $match )        { $keep-literal = True; }
  method no-elements-literal ( $match ) { $keep-literal = True; }
  method no-elements ( $match )         { $keep-literal = False; }


  method body1-start ( $match )         { self!process-tag(); }

  method no-elements-text ( $match )    { return self.body1-text($match); }

  method body1-text ( $match )          { self!process-text($match); }

  method body1-end ( $match ) {
    # Go back one level .New child tags will overwrite the previous child
    # on the stack as those are not needed anymore.
    #
    $current-element-idx--;
say '--';
    if $deferred-calls[$current-element-idx].defined 
       and $el-stack[$current-element-idx] ~~ XML::Element
       and $el-stack[$current-element-idx+1].name eq 'PLACEHOLDER-ELEMENT' {

      # Call the deferred method and pass the element 'PLACEHOLDER-ELEMENT' and
      # all children below it. The method must remove this element before
      # returning otherwise it will become an xml tag.
      #
      $deferred-calls[$current-element-idx](
        self,
        :content-body($el-stack[$current-element-idx + 1])
      );

      # Call done, now reset
      #
      $deferred-calls[$current-element-idx] = Any;
    }
  }

  method body2-start ( $match )         { self!process-tag(); }

  method body2-text ( $match )          { self!process-text($match); }

  method body2-end ( $match ) {
say "b2e: $match";
    # Go back one level .New child tags will overwrite the previous child
    # on the stack as those are not needed anymore.
    #
    $current-element-idx--;
say "--";
  }

  # Idea to count lines in the source
  #
  method ws ( $match ) {
#    ~$match ~~ m:g/(\n)/;
#say "N-" x $/.elems;
  }

  #-----------------------------------------------------------------------------
  # Process tags
  #
  method !process-tag ( ) {

    # Check the tag type
    #
    $tag-name ~~ s/^$tag-type//;

    # Check substituteable tags starting with $.
    #
    if $tag-type ~~ m/^'$.'/ {
      # Get modulename
      #
      $tag-type ~~ m/\$\.(<-[\.]>+)/;
      my $module = $/[0].Str;

      # Test if method exists in module
      #
      if $!objects{$module}.symbols{$tag-name}:exists {
        my $s = $!objects{$module}.symbols{$tag-name};
        $tag-name = $s<tag-name>;

        # Add attribute to existing
        #
        for $s<attributes>.kv -> $k,$v { $attrs{$k} = $v; }

        # And register element
        #
        self!register-element( $tag-name, $attrs);
      }
    }

    # Check method tags starting with $!
    #
    elsif $tag-type ~~ m/^'$!'/ {

      # Get the module name and remove tag type from tag string to get method
      # Then check existence of method in module.
      #
      $tag-type ~~ m/\$\!(<-[\.]>+)/;
      my $module = $/[0].Str;
      if $!objects{$module}.can($tag-name) {

        # Must make a copy of the tag-name to a local variable. If tag-name is
        # used directly in the closure, the name is not 'frozen' to the value when
        # the call is defined.
        #
        my $tgnm = $tag-name;
        $deferred-calls[$current-element-idx]
           = method (XML::Node :$content-body) {
#say "CF: ", callframe(1).file, ', ', callframe(1).line;
#say "Called, text = $module, $tgnm, $tag-type";
          $!objects{$module}."$tgnm"(
            $el-stack[$current-element-idx],
            $attrs,
            :$content-body
          );
        }

        self!register-element( 'PLACEHOLDER-ELEMENT', {});
      }
    }

    elsif $tag-type eq '$' {
      self!register-element( $tag-name, $attrs);
    }

    else {

    }
  }

  # Create an xml element and add its attributes. When the $current-element-idx
  # is not yet defined, a new document must be created and pointers initialized.
  # The array is like a stack of elements of which each element is a child
  # of the one before it in the array. The last one in the array is the one  to
  # which text or other elements are appended. In body1-text text elements are
  # appended to this last element When the block is finished (at body1-end) the
  # pointer is moved up to the parent element in the array.
  #
  method !register-element ( Str $tag-name, Hash $attrs ) {
    # Test if index is defined.
    #
    my $child-element = XML::Element.new( :name($tag-name), :attribs($attrs));
    if $current-element-idx.defined {
      $el-stack[$current-element-idx].append($child-element);
      $el-stack[$current-element-idx + 1] = $child-element;
#say "E: {$child-element.name} append on $current-element-idx, {$el-stack[$current-element-idx].name}";

      # Point to the next level in case there is another tag found in the 
      # current body. This element must become the child element of the
      # current one.
      #
      $current-element-idx++;
say "++ $tag-name";
    }

    else {
      # First element is a root element
      #
      $current-element-idx = 0;
      $el-stack[$current-element-idx] = $child-element;
      $!xml-document .= new($el-stack[$current-element-idx]);
say "Root: $tag-name";
    }
  }

  # Process the text after finding body terminator
  #
  method !process-text ( $match ) {
    my $esc-text = self!process-esc(~$match);
say "btc 0: $esc-text";
    $esc-text ~~ s/^\n+//;
#    $esc-text ~~ s/^\s+//;
    my $xml;
    if $keep-literal {
      $esc-text ~~ s/\s+$//;
      my $min-spaces = Inf;

      # Get all spaces at the start of a line
      #
      $esc-text ~~ m:g/^^(\s+)/;
      my @indents = $/[];

      # Then get the length
      for @indents -> $indent {
        my Str $i = ~$indent;
        $i ~~ s/^\n//;
        my $nspaces = $i.chars;
        $min-spaces = $nspaces if $nspaces < $min-spaces;
      }

say "ET: '$esc-text',$min-spaces\n";
      $esc-text ~~ s:g/^^\s**{$min-spaces}// unless $min-spaces == Inf;

      $xml = Semi-xml::Text.new(:text($esc-text)) if $esc-text.chars > 0;
    }

    else {
      $esc-text ~~ s/^\s+//;
      $xml = XML::Text.new(:text($esc-text)) if $esc-text.chars > 0;
    }

    if $xml.defined {
      $el-stack[$current-element-idx].append($xml);
    }
  }

  # Substitute some escape characters in entities and remove the remaining
  # backslashes.
  #
  method !process-esc ( Str $esc is copy --> Str ) {

    # Entity must be known in the xml result!
    #
    $esc ~~ s:g/\\\s/\&nbsp;/;
    $esc ~~ s:g/\\\</\&lt;/;
    $esc ~~ s:g/\\\>/\&gt;/;

    # Remove rest of the backslashes
    #
    $esc ~~ s:g/\\//;

    return $esc;
  }
}




