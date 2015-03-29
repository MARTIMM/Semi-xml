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
  my Array $element-stack;
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
      $element-stack = [];
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

  method body-start ( $match ) {
    $tag-name ~~ s/^$tag-type//;
#say "BS: $tag-name, $tag-type";

    # Calls which are deferred must be called now otherwise the call will
    # be overwitten before the end og the bode is reached..
    #
#    if $!deferred_call.defined {
#      die "A method calls body text cannot have any tags, Tags are ignored";
#    }

    # Reset any deferred call meganisms
    #
#    $!deferred_call = Any;

    if $tag-type ~~ m/^'$.'/ {
      $tag-type ~~ m/\$\.(<-[\.]>+)/;
      my $module = $/[0].Str;
      if $!objects{$module}.symbols{$tag-name}:exists {
        my $s = $!objects{$module}.symbols{$tag-name};
        $tag-name = $s<tag-name>;

        # Add attribute to existing
        #
        for $s<attributes>.kv -> $k,$v { $attrs{$k} = $v; }

        self!register-element( $tag-name, $attrs);
      }
    }

    elsif $tag-type ~~ m/^'$!'/ {
#      $current-element-idx++;

      $tag-type ~~ m/\$\!(<-[\.]>+)/;
      my $module = $/[0].Str;
      if $!objects{$module}.can($tag-name) {
        # Defer the call until after the body content. The method is stored
        # in the array $deferred-calls at the position as the currently
        # processed element using $current-element-idx
        # 
#        $!deferred_call = method (XML::Text :$content-text) {
#say "Make call: $current-element-idx -> {$current-element-idx + 1}, $module, $tag-name, $tag-type";
        
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
            $element-stack[$current-element-idx],
            $attrs,
            :$content-body
#            :$content-text
          );
        }

        self!register-element( 'PLACEHOLDER-ELEMENT', {});
#        $current-element-idx++;
      }
    }

    elsif $tag-type eq '$' {
      self!register-element( $tag-name, $attrs);
    }

    else {

    }
  }

  method body-end ( $match ) {
    # Go back one level .New child tags will overwrite the previous child
    # on the stack as those are needed anymore.
    #
#say "\nEnd 0: from $current-element-idx -> {$current-element-idx -1}";

      $current-element-idx--;
#say "End 1: {?$deferred-calls[$current-element-idx]}";
#say "End 2: {$element-stack[$current-element-idx] ~~ XML::Element}";
#say "End 3: {$element-stack[$current-element-idx+1].name eq 'PLACEHOLDER-ELEMENT'}";
#say "End 4: {$element-stack[$current-element-idx+1].name}";
#say "End 5: tag = $tag-name";
    if $deferred-calls[$current-element-idx].defined 
       and $element-stack[$current-element-idx] ~~ XML::Element
       and $element-stack[$current-element-idx+1].name eq 'PLACEHOLDER-ELEMENT' {
#      $!content-body //= XML::Text.new(:text(''));
#say "BE: $!deferred-call-idx, $deferred-calls[$!deferred-call-idx]";
#say "BE 1: $current-element-idx, {$element-stack[$current-element-idx].name}";
#      my XML::Node @nodes = $element-stack[$current-element-idx + 1].nodes;
      $deferred-calls[$current-element-idx](
        self,
#        :$!content-body
        :content-body($element-stack[$current-element-idx + 1])
      );

#say "R: {$element-stack[$current-element-idx + 1].name}";
#     if $element-stack[$current-element-idx + 1].name eq 'PLACEHOLDER-ELEMENT' {
#       $element-stack[$current-element-idx + 1].remove;
#     }
#       $!content-body = Any;

      # Call done, now reset
      #
      $deferred-calls[$current-element-idx] = Any;
    }

#    else {
#say "End: back to $current-element-idx";

#    }
  }

  method no-elements-text ( $match ) { return self.body-text($match); }

  method body-text ( $match ) {

    # Add textual items after cleanup of escaped characters.
    #
    my $xml;
    my $esc-text = ~$match;
    $esc-text ~~ s:g/\\\s/\&nbsp;/;
    $esc-text ~~ s:g/\\//;

    $esc-text ~~ s/^\n+//;
    $esc-text ~~ s/\s+$//;

    # Test if body starts with '[=' or [+.for which content must be kept
    # exactly as is.
    #
    if $keep-literal {
      $esc-text ~~ m:g/^^(\s+)/;
      my $min-spaces = Inf;
      my @indents = $/[];
      for @indents -> $indent {
        my Str $i = ~$indent;
        $i ~~ s/^\n//;
        my $nspaces = $i.chars;
        $min-spaces = $nspaces if $nspaces < $min-spaces;
      }

#say "ET: '$esc-text',$min-spaces\n";
      $esc-text ~~ s:g/^^\s**{$min-spaces}// unless $min-spaces == Inf;

      $xml = Semi-xml::Text.new(:text($esc-text)) if $esc-text.chars > 0;
    }

    else {
      $esc-text ~~ s/^\s+//;
      $xml = XML::Text.new(:text($esc-text)) if $esc-text.chars > 0;
    }

    if $xml.defined {
      # When there was a deferred call stored to run
      #
#      if $!deferred-call-idx >= 0 {
#        $!content-body = $xml;
#      }

#      else {
#say "T: text append on $current-element-idx, {$element-stack[$current-element-idx].name}";
        $element-stack[$current-element-idx].append($xml);
#        $!content-body = Any;
#      }
    }
  }

  # Create an xml element and add its attributes. When the $current-element-idx
  # is not yet defined, a new document must be created and pointers initialized.
  # The array is like a stack of elements of which each element is a child
  # of the one before it in the array. The last one in the array is the one  to
  # which text or other elements are appended. In body-text text elements are
  # appended to this last element When the block is finished (at body-end) the
  # pointer is moved up to the parent element in the array.
  #
  method !register-element ( Str $tag-name, Hash $attrs ) {
    # Test if index is defined.
    #
    my $child-element = XML::Element.new( :name($tag-name), :attribs($attrs));
    if $current-element-idx.defined {
      $element-stack[$current-element-idx].append($child-element);
      $element-stack[$current-element-idx + 1] = $child-element;
#say "E: {$child-element.name} append on $current-element-idx, {$element-stack[$current-element-idx].name}";

      # Point to the next level in case there is another tag found in the 
      # current body. This element must become the child element of the
      # current one.
      #
      $current-element-idx++;
    }

    else
    {
      # First element is a root element
      #
      $current-element-idx = 0;
      $element-stack[$current-element-idx] = $child-element;
      $!xml-document .= new($element-stack[$current-element-idx]);
#say "Root: $current-element-idx, {$element-stack[$current-element-idx].name}";
    }
  }
  
  # Idea to count lines in the source
  #
  method ws ( $match ) {
#    ~$match ~~ m:g/(\n)/;
#say "N-" x $/.elems;
  }
}




