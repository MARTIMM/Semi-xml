use v6;
use XML;

class Semi-xml::Text is XML::Text {
  method Str {
    return $.text;
  }
}

role Semi-xml::Actions {
  has XML::Document $.xml-document;

  has Hash $.symbols;
  has Hash $.config;
#  my Str $parent-key;

  my Hash $config-key = {};
  my Str $config-path;
  my Str $config-value;

  my Array $element-stack;
  my Int $current-element-idx;

  my Str $tag-name;

  my Hash $attrs;
  my Str $attr-key;

  my Bool $keep-literal = False;

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

  method prelude ( $match ) {
    if $!config<module>:exists {
      for $!config<module>.kv -> $key, $value {
        my $code = qq:to/EOCODE/;
          use $value;
          $value.new;
        EOCODE
#say "C:\n$code\n";

        my $obj = EVAL($code);
#say "O: {$obj.^name}, {$obj.^attributes}";

        say $! if $!;

        for $obj.symbols.kv -> $k, $v {
          $!symbols{$k} = $v;
#say "KV: $k, $v";
        }
      }
    }
  }

  method tag-name ( $match ) {

    # Initialize on start of a new tag. Everything of any previous tag is
    # handled and stored.
    #
    $tag-name = Str;

    $attr-key = Str;
    $attrs = {};

#print "$match";

    $tag-name = ~$match;
    $tag-name ~~ s/\$//;
    if $!symbols{$tag-name} {
      my $s = $!symbols{$tag-name};
      $tag-name = $s<tag-name>;
      $attrs = $s<attributes> if $s<attributes>:exists;
    }

#`{{
    elsif CALLER::{~$match} {
      $tag = CALLER::{~$match};
    }

    elsif OUTER::{~$match} {
      $tag = OUTER::{~$match};
    }

    elsif DYNAMIC::{~$match} {
      $tag = DYNAMIC::{~$match};
    }
}}

#    else {
#      $tag-name = ~$match;
#      $tag-name ~~ s/\$//;
#    }
#say " -> $tag-name";
  }

  method attr-key ( $match ) {
    $attr-key = ~$match;
  }

  method attr-value ( $match ) {
    $attrs{$attr-key} = ~$match;
  }

  # Before the body starts, save the tag name and create the element with
  # its attributes.
  #
  method body-start ( $match ) {
    $keep-literal = False;
    $tag-name ~~ s/\s.*$$//;

    # Test if index is defined.
    #
    if $current-element-idx.defined {
      my $child-element = XML::Element.new( :name($tag-name),
                                            :attribs($attrs)
                                          );
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
      $element-stack[$current-element-idx] = 
          XML::Element.new( :name($tag-name),
                            :attribs($attrs)
                          );

      $!xml-document .= new($element-stack[$current-element-idx]);
    }
  }

  method body-end ( $match ) {
    # Go back one level .New child tags will overwrite the previous child
    # on the stack as those are needed anymore.
    #
    $current-element-idx--;
  }

  method lit-body-start ( $match ) {
    $keep-literal = True;
  }

  method body-text ( $match ) {
    # Add textual items after cleanup of spaces.
    # Must be tested when there are tags for which content must be kept
    # exactly as is.
    #
    my $xml;
    my $esc-text = ~$match;
    $esc-text ~~ s:g/\\//;
    if $keep-literal {
      $xml = Semi-xml::Text.new(:text($esc-text));
    }

    else {
      $xml = XML::Text.new(:text($esc-text));
    }

    $element-stack[$current-element-idx].append($xml);
  }
}




