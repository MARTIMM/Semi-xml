use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Test {

  has Array $!test-parts = [];
  has Int $!test-count = 0;

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

say "T: ", ~$parent;
say "B: ", ~$content-body;

    $!test-parts.push: {
      test-comment => $content-body,
      test-code => "$attrs<t>, 'T$!test-count'" // ''
    };


say $!test-parts.elems, ', ', $!test-parts.perl;
    $!test-count++;
    $parent;
  }
}
