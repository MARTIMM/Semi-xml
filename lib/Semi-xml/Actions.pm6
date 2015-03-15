use v6;
use XML;

class Semi-xml::Text is XML::Text {
  method Str ( ) {
    return $.text;
  }
}

class Semi-xml::Actions {
  has XML::Document $.xml-document;

  has Hash $.objects = {};
  has Hash $.config = {};

  my Hash $config-key = {};
  my Str $config-path;
  my Str $config-value;

  my Array $element-stack;
  my Int $current-element-idx;

  my Str $tag-name;
  my Str $tag-type;

  my Hash $attrs;
  my Str $attr-key;

  my Bool $keep-literal;

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
  }

  method tag-name ( $match ) {
    # Initialize on start of a new tag. Everything of any previous tag is
    # handled and stored.
    #
    $attr-key = Str;
    $attrs = {};

    $tag-name = ~$match;
  }

  method attr-key ( $match ) {
    $attr-key = ~$match;
  }

  method attr-s-value ( $match ) {
    self!attr-value(~$match);
  }

  method attr-q-value ( $match ) {
    self!attr-value(~$match);
  }

  method attr-qq-value ( $match ) {
    self!attr-value(~$match);
  }

  method !attr-value ( $m is copy ) {
    $m ~~ s:g/\"/\&quot;/;
    $attrs{$attr-key} = $m;
  }

  # Before the body starts, save the tag name and create the element with
  # its attributes.
  #
  method no-elements-literal ( $match ) {
    $keep-literal = (~$match eq '+' ?? True !! False);
  }

  method keep-literal ( $match ) {
    $keep-literal = (~$match eq '=' ?? True !! False);
  }

  method body-start ( $match ) {
    $tag-name ~~ s/^$tag-type//;

    if $tag-type ~~ m/^'$.'/ {
      $tag-type ~~ m/\$\.(<-[\.]>+)/;
      my $module = $/[0].Str;
      if $!objects{$module}.symbols{$tag-name}:exists {
          my $s = $!objects{$module}.symbols{$tag-name};
          $tag-name = $s<tag-name>;
          for $s<attributes>.kv -> $k,$v { $attrs{$k} = $v; }

          self!register-element( $tag-name, $attrs);
      }
    }

    elsif $tag-type ~~ m/^'$!'/ {
      $tag-type ~~ m/\$\!(<-[\.]>+)/;
      my $module = $/[0].Str;
      if $!objects{$module}.can($tag-name) {
        $!objects{$module}."$tag-name"( $element-stack[$current-element-idx],
                                        $attrs
                                      );
      }

      $current-element-idx++;
    }

    elsif $tag-type eq '$' {
      self!register-element( $tag-name, $attrs);
    }
    
    else {
    
    }
  }

  method !register-element ( Str $tag-name, Hash $attrs ) {
    # Test if index is defined.
    #
    my $child-element = XML::Element.new( :name($tag-name), :attribs($attrs));
    if $current-element-idx.defined {
      $element-stack[$current-element-idx].append($child-element);
      $element-stack[$current-element-idx + 1] = $child-element;

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
    }
  }

  method body-end ( $match ) {
    # Go back one level .New child tags will overwrite the previous child
    # on the stack as those are needed anymore.
    #
    $current-element-idx--;
  }

  method no-elements-text ( $match ) { return self.body-text($match); }

  method body-text ( $match ) {
    # Add textual items after cleanup of spaces.
    #
    my $xml;
    my $esc-text = ~$match;
    $esc-text ~~ s:g/\\//;

    # Test if body starts with '[='.for which content must be kept
    # exactly as is.
    #
    if $keep-literal {
      $xml = Semi-xml::Text.new(:text($esc-text));
    }

    else {
      $esc-text ~~ s/^\s+//;
      $esc-text ~~ s/\s+$//;
      $xml = XML::Text.new(:text($esc-text));
    }

    $element-stack[$current-element-idx].append($xml);
  }
}




