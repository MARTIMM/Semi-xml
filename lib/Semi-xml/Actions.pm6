use v6;
use XML;

package Semi-xml {

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
        $!txt ~~ s:g/\s+$//;  ## Chop out trailing spaces.
        $!txt ~~ s:g/^\s+//;  ## Chop out leading spaces.
        $!txt .= chomp;       ## Remove a trailing newline if it exists.
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
      $content-body.remove;

      $parent.append(XML::Text.new(:text(Date.today().Str)));
    }

    # $!SxmlCore.date-time []
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

    # $!SxmlCore.comment []
    #
    method comment ( XML::Element $parent,
                     Hash $attrs,
                     XML::Node :$content-body
                   ) {
      $parent.append(XML::Comment.new(:data([~] $content-body.nodes)));
      $content-body.remove;
    }

    # $!SxmlCore.cdata []
    #
    method cdata ( XML::Element $parent,
                   Hash $attrs,
                   XML::Node :$content-body
                 ) {
      $parent.append(XML::CDATA.new(:data([~] $content-body.nodes)));
      $content-body.remove;
    }

    # $!SxmlCore.pi []
    #
    method pi ( XML::Element $parent,
                Hash $attrs,
                XML::Node :$content-body
              ) {
      $parent.append(XML::PI.new(:data([~] $content-body.nodes)));
      $content-body.remove;
    }
  }

  #-----------------------------------------------------------------------------
  #
  class Actions {
    our $debug = False;

    # Objects hash with one predefined object for core methods
    #
    has Hash $.objects = { SxmlCore => Semi-xml::SxmlCore.new() };
    has Hash $.config = {};

    my Hash $config-key = {};
    my Str $config-path;
    my Str $config-value;

    my XML::Document $xml-document;
    my Int $current-el-idx;
    my Array $el-stack;
    my Array $deferred-calls;
    my Array $el-keep-literal;

    my Str $tag-name;
    my Str $tag-type;

    my Hash $attrs;
    my Str $attr-key;

    my Bool $keep-literal;
    my Bool $has-comment;


    # Initialize some variables when init is set. Must be done when a new object
    # is created: the variables are 'seen' in the other object
    #
    submethod BUILD ( Bool :$init ) {
      if ?$init {
        $current-el-idx = Int;
        $el-stack = [];
        $deferred-calls = [];
        $has-comment = False;
      }
    }

    #-----------------------------------------------------------------------------
    # All config entries are like: '/a/b/c: v;' This must be evauluated as
    # "$!config<$config-path>='$config-value'" so it becomes a key value pair
    # in the config.
    #
    method config-entry ( $match ) {
      if $config-path.defined and $config-value.defined {

        # Remove first character if /
        #
        $config-path ~~ s/^\///;

        # Remove in between / with ><. After that, enclose the line with <...>.
        #
        $config-path ~~ s:g/ \/ /\>\</;
        $config-path = "\$!config\<$config-path\>='$config-value'";

        EVAL("$config-path");
      }
    }

    method config-keypath ( $match ) { $config-path = ~$match; }
    method config-value ( $match )   { $config-value = ~$match; }

    # After all of the prelude is stored, check if the 'module' keyword is used.
    # If so, evaluate the module and save the created object in $!objects. E.g.
    # suppose a config 'module/file: Sxml::Lib::File;' is used then the object
    # created from that module call '$obj = Sxml::Lib::File.new();' and is stored
    # like '$!objects<file> = $obj;'. A library path is used when config key
    # 'library/file: path/to/mod' is used in previous example.
    #
    method prelude ( $match ) {

      if $!config<option><debug>:exists and $!config<option><debug> {
        say "\nTurn debugging on\n";
        $debug = True;
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
#say "\n$code\n";
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
    }

    method tag-name ( $match ) {
      # Initialize on start of a new tag. Everything of any previous tag is
      # handled and stored.
      #
      $attr-key = Str;
      $attrs = {};

      $tag-name = ~$match;
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

    method body1-start ( $match )         { self!process-tag(); }
    method body1-text ( $match )          { self!process-text($match); }
    method body1-end ( $match )           { self!process-body-end(); }

    method body2-start ( $match )         { self!process-tag(); }
    method body2-text ( $match )          { self!process-text($match); }
    method body2-end ( $match )           { self!process-body-end(); }

    # Idea to count lines in the source
    #
    method ws ( $match ) {
  #    ~$match ~~ m:g/(\n)/;
  #say "N-" x $/.elems;
    }

    method comment ( $match is rw ) {
      $has-comment = True;
    }

    #-----------------------------------------------------------------------------
    # Process tags
    #
    method !process-tag ( ) {

      # Check the tag type
      #
      $tag-name ~~ s/^$tag-type//;

      # Check substitutable tags starting with $.
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
          # the call is defined.. Same goes for attributes.
          #
          my $tgnm = $tag-name;
          my $mod = $module;
          my $ats = $attrs;
          my $cei = $current-el-idx;
#say "\nCan do $tgnm in module $mod, ",
#  $cei > 0 ?? $el-stack[$cei - 1].name !! 'top',
#  ', ', $el-stack[$cei].name;

          $deferred-calls[$cei] =
            method (XML::Node :$content-body) {
#say "\nCalled $tgnm in module $mod";
              $!objects{$mod}."$tgnm"( $el-stack[$cei], $ats, :$content-body);
          }

          self!register-element( 'PLACEHOLDER-ELEMENT', {});
        }

        else {
          die "No method '$tag-name' and/or module link '$module' found";
        }
      }

      elsif $tag-type eq '$*<' {
        self!register-element( $tag-name, $attrs, :decorate-left);
      }

      elsif $tag-type eq '$*>' {
        self!register-element( $tag-name, $attrs, :decorate-right);
      }

      elsif $tag-type eq '$*' {
        self!register-element( $tag-name, $attrs, :decorate);
      }

      elsif $tag-type eq '$' {
        self!register-element( $tag-name, $attrs);
      }

      else {

      }
    }

    # Create an xml element and add its attributes. When the $current-el-idx
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
      #
      my $child-element = XML::Element.new( :name($tag-name), :attribs($attrs));

      if $current-el-idx.defined {
        $el-stack[$current-el-idx].append(Semi-xml::Text.new(:text(' ')))
          if $decorate-left or $decorate;
        $el-stack[$current-el-idx].append($child-element);
        $el-stack[$current-el-idx].append(Semi-xml::Text.new(:text(' ')))
          if $decorate-right or $decorate;
        $el-stack[$current-el-idx + 1] = $child-element;

        # Copy current 'keep literal' state.
        #
        $el-keep-literal[$current-el-idx + 1] = $el-keep-literal[$current-el-idx];

        # Point to the next level in case there is another tag found in the 
        # current body. This element must become the child element of the
        # current one.
        #
        $current-el-idx++;
      }

      else {
        # First element is a root element
        #
        $current-el-idx = 0;
        $el-stack[$current-el-idx] = $child-element;
        $el-keep-literal[$current-el-idx] = False;
        $xml-document .= new($el-stack[$current-el-idx]);
      }
    }

    # Process the text after finding body terminator
    #
    method !process-text ( $match ) {

      # Check if there is a comment found in this text, if so remove it and then
      # modify/remove escape characters
      #
      my $text = ~$match;
      if $has-comment {
        $text ~~ s:g/ \n \s* '#' <-[\n]>* \n /\n/;
        $has-comment = False;
      }
      $text = self!process-esc($text);

      my $xml;
      $el-keep-literal[$current-el-idx] ||= $keep-literal;
      if $el-keep-literal[$current-el-idx] {
  #    if $keep-literal {
  #say "!PRT lit: $el-keep-literal[$current-el-idx], {$el-stack[$current-el-idx].name}";

  # At the moment too complex to handle removal of a minimal indentation
  if 0 {
  #if $keep-literal {
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
        $xml = Semi-xml::Text.new(:text($text)) if $text.chars > 0;
      }

      else {
        $text ~~ s/^\s+/ /;
        $text ~~ s/\s+$/ /;
  #      $xml = XML::Text.new(:text($text)) if $text.chars > 0;
        $xml = Semi-xml::Text.new( :text($text), :strip)
          if $text.chars > 0;
      }

      $el-stack[$current-el-idx].append($xml) if $xml.defined;
    }

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

    # Process body ending
    #
    method !process-body-end ( ) {
      # Go back one level .New child tags will overwrite the previous child
      # on the stack as those are not needed anymore.
      #
      $current-el-idx--;

      if $deferred-calls[$current-el-idx].defined 
         and $el-stack[$current-el-idx] ~~ XML::Element
         and $el-stack[$current-el-idx + 1].name eq 'PLACEHOLDER-ELEMENT' {

        # Call the deferred method and pass the element 'PLACEHOLDER-ELEMENT' and
        # all children below it. The method must remove this element before
        # returning otherwise it will become an xml tag.
        #
        $deferred-calls[$current-el-idx](
          self,
          :content-body($el-stack[$current-el-idx + 1])
        );
#say "\nEl = $current-el-idx\n\n", $el-stack[$current-el-idx].Str, "\n\n";

        # Remove PLACEHOLDER-ELEMENT if still available
        #
        $el-stack[$current-el-idx + 1].remove
          if ?$el-stack[$current-el-idx + 1];
      }

      # Call done, now reset
      #
      if $current-el-idx >= 0 {
        # Remove method from stack
        #
        $deferred-calls[$current-el-idx] = Any;

        # Reset the 'keep literal state'
        #
        $el-keep-literal[$current-el-idx + 1] = False;
      }
    }

    method get-document ( --> XML::Document ) {
      return $xml-document;
    }
  }
}



