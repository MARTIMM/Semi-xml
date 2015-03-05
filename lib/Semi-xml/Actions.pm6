use v6;
use XML;

role Semi-xml::Actions {
  has XML::Document $.xml-document;

  my Hash $config-key = {};
  has Hash $.config;
  my Str $parent-key;

  my Str $config-path;
  my Str $config-value;

  my Array $element-stack;
  my Int $current-element-idx;

  my Str $tag-name;
  
  my Hash $attrs;
  my Str $attr-key;

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

  method tag-name ( $match ) {

    # Initialize on start of a new tag. Everything of any previous tag is
    # handled and stored.
    #
    $tag-name = Str;

    $attr-key = Str;
    $attrs = {};

#print "$match";
    if ::{~$match} {
      $tag-name = ::{~$match};
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

    else {
      $tag-name = ~$match;
      $tag-name ~~ s/\$//;
    }
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
#    my $tag-name = $tag;
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

  method body-text ( $match ) {
    # Only add textual items. Empty lines are skipped.
    # Must be tested when there are tags for which content must be kept
    # exactly as is.
    #
    my $txt = ~$match;
    $txt ~~ s/\s+/ /;

    my $esc-text = ~$match;
    $esc-text ~~ s:g/\\//;
    my $xml = XML::Text.new(:text($esc-text));
    $element-stack[$current-element-idx].append($xml);
  }
}




