use v6.c;
use SemiXML;

class M::m1 {

  # method 1 can be used at top of document
  method mth1 ( XML::Element $parent,
                 Hash $attrs,
                 XML::Element :$content-body

                 --> XML::Element
               ) {

    my XML::Element $p .= new(:name('p'));
    $parent.append($p);
    $parent;
  }

  # method 2 can not be used at top of document
  method mth2 ( XML::Element $parent,
                 Hash $attrs,
                 XML::Element :$content-body

                 --> XML::Element
               ) {

    my XML::Element $p .= new(:name('p'));
    $parent.append($p);
    $p .= new(:name('p'));
    $parent.append($p);

    # Eat from the end of the list and add just after the container element.
    # Somehow they get lost from the array when done otherwise.
    #
    my Int $nbr-nodes = $content-body.nodes.elems;
    $p.insert($_) for $content-body.nodes.reverse;
    $p.append(SemiXML::Text.new(:text("Added $nbr-nodes xml nodes")));

    $parent;
  }
}

