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
  method date ( XML::Element $parent, Hash $attrs ) {
    $parent.append(XML::Text.new(:text(Date.today().Str)));
  }

  # $SxmlCore.date-time []
  #
  method date-time ( XML::Element $parent, Hash $attrs ) {
    my $date-time = DateTime.now().Str;
    $date-time ~~ s/'T'/ /;
    $date-time ~~ s/'+'/ +/;
    my $txt-e = XML::Text.new(:text($date-time));
    $parent.append($txt-e);
  }
}

class Semi-xml::Actions {
  our $debug = False;

  has XML::Document $.xml-document;

  # Objects hash with one predefined object for core methods
  #
  has Hash $.objects = { SxmlCore => Semi-xml::SxmlCore.new()};
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

  my Bool $keep-literal = False;

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

#  method body-contents ( $match ) {
#say "BC: '$match'";
#  }
  
  method body-start ( $match ) {
    $tag-name ~~ s/^$tag-type//;
#say "BS: $tag-name, $tag-type, '$match'";

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

  method body-end ( $match ) {
    # Go back one level .New child tags will overwrite the previous child
    # on the stack as those are needed anymore.
    #
    $current-element-idx--;
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
#say "KL: {$keep-literal ?? 'Y' !! 'N'}, $esc-text";
    if $keep-literal {
      $esc-text ~~ m:g/^^(\s+)/;
#say "P 0: {$/.perl}";
      my $min-spaces = Inf;
      my @indents = $/[];
      for @indents -> $indent {
        my Str $i = ~$indent;
        $i ~~ s/^\n//;
        my $nspaces = $i.chars;
#say "Chrs: $nspaces";
        $min-spaces = $nspaces if $nspaces < $min-spaces;
      }

#say "I: $min-spaces";
      $esc-text ~~ s:g/^^\s**{$min-spaces}//;

      $xml = Semi-xml::Text.new(:text($esc-text)) if $esc-text.chars > 0;
    }

    else {
#say "P 1: '$esc-text'";
      $esc-text ~~ s/^\s+//;
#      $esc-text ~~ s/\s+$//;
      $xml = XML::Text.new(:text($esc-text)) if $esc-text.chars > 0;
    }

    $element-stack[$current-element-idx].append($xml) if $xml.defined;
  }

  method !register-element ( Str $tag-name, Hash $attrs ) {
    # Test if index is defined.
    #
#say "XE: '$tag-name'";
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
}




