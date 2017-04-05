use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

use XML;
#use SemiXML::Sxml;
use SxmlLib::SxmlHelper;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
class Code {

  has Array $!parts = [ ];
  has Int $!count = 0;

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    $!parts.push: { code => $content-body, };

    my XML::Element $c = append-element( $parent, 'code');
    append-element( $c, :text($!count.Str));

    $!count++;
    $parent;
  }

#`{{
  #-----------------------------------------------------------------------------
#TODO not ok to use example
  method example (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list
    --> XML::Node
  ) {
say "E: $content-body";
    my XML::Element $pre = append-element( $parent, 'pre', {:class<example>});
    $parent.append($pre);
}}#`{{
    # <pre> used to display code in
    my Str $class = 'test-block-code';
    if $!highlight-code {
      $class = "prettyprint $!highlight-language";
      if $!linenumbers {
        $class ~= ' linenums' ~
                  ($line-number == 1 ?? '' !! ":$line-number");
      }
    }
}}#`{{

    for $content-body.nodes.reverse -> $node {
      $pre.insert($node);
    }
say $parent;
    $parent;
  }
}}

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method get-code-part ( Int $entry --> XML::Element ) {

    $!parts[$entry]<code>;
  }
}
