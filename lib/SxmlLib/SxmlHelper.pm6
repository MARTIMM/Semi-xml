use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Text;
use XML;
use XML::XPath;

#-------------------------------------------------------------------------------
class SxmlHelper {

  #-----------------------------------------------------------------------------
#TODO $config should come indirectly from $!refined-config
  multi sub save-xml (
    Str:D :$filename, XML::Element:D :$document!,
    Hash :$config = {}, Bool :$formatted = False,
  ) is export {

    my XML::Document $root .= new($document);
    save-xml( :$filename, :document($root), :$config, :$formatted);
  }

  multi sub save-xml (
    Str:D :$filename, XML::Document:D :$document!,
    Hash :$config = {}, Bool :$formatted = False
  ) is export {

    # Get the document text
    my Str $text;

    # Get the top element name
    my Str $root-element = $document.root.name;
#      $root-element ~~ s/^(<-[:]>+\:)//;

    # If there is one, try to generate the xml
    if ?$root-element {

      # Check if a http header must be shown
      my Hash $http-header = $config<option><http-header> // {};

      if ? $http-header<show> {
        for $http-header.kv -> $k, $v {
          next if $k ~~ 'show';
          $text ~= "$k: $v\n";
        }
        $text ~= "\n";
      }

      # Check if xml prelude must be shown
      my Hash $xml-prelude = $config<option><xml-prelude> // {};

      if ? $xml-prelude<show> {
        my $version = $xml-prelude<version> // '1.0';
        my $encoding = $xml-prelude<encoding> // 'utf-8';
        my $standalone = $xml-prelude<standalone>;

        $text ~= '<?xml version="' ~ $version ~ '"';
        $text ~= ' encoding="' ~ $encoding ~ '"';
        $text ~= ' standalone="' ~ $standalone ~ '"' if $standalone;
        $text ~= "?>\n";
      }

      # Check if doctype must be shown
      my Hash $doc-type = $config<option><doctype> // {};

      if ? $doc-type<show> {
        my Hash $entities = $doc-type<entities> // {};
        my Str $start = ?$entities ?? " [\n" !! '';
        my Str $end = ?$entities ?? "]>\n" !! ">\n";
        $text ~= "<!DOCTYPE $root-element$start";
        for $entities.kv -> $k, $v {
          $text ~= "<!ENTITY $k \"$v\">\n";
        }
        $text ~= "$end\n";
      }

      $text ~= ? $document ?? $document.root !! '';
    }

    # Save the text to file
    if $formatted {
      my Proc $p = shell "xmllint -format - > $filename", :in;
      $p.in.say($text);
      $p.in.close;
    }

    else {
      spurt( $filename, $text);
    }
  }

  #-----------------------------------------------------------------------------
  sub append-element (
    XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
    --> XML::Node
  ) is export {

    # create a text element, even when it is an empty string.
    my XML::Node $text-element = SemiXML::Text.new(:$text) if $text.defined;

    # create an element only when the name is defined and not empty
    my XML::Node $element =
       XML::Element.new( :$name, :attribs(%$attributes)) if ? $name;

    # if both are created than add text to the element
    if ? $element and ? $text-element {
      $element.append($text-element);
    }

    # if only text, then the element becomes the text element
    elsif ? $text-element {
      $element = $text-element;
    }

    # else $name -> no change to $element. No name and no text is an error.
#    die "No element nor text defined" unless ? $element;

    $parent.append($element);
    $element;
  }

  #-----------------------------------------------------------------------------
  sub insert-element (
    XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text
    --> XML::Node
  ) is export {

    my XML::Node $text-element = SemiXML::Text.new(:$text) if $text.defined;
    my XML::Node $element =
       XML::Element.new( :$name, :attribs(%$attributes)) if ? $name;

    if ? $element and ? $text-element {
      $element = SemiXML::Text.new(:$text);
    }

    elsif ? $text-element {
      $element = $text-element;
    }

    $parent.insert($element);
    $element;
  }

  #-----------------------------------------------------------------------------
  sub before-element (
    XML::Element $node, Str $name = '', Hash $attributes = {}, Str :$text = ''
    --> XML::Node
  ) is export {

    my XML::Node $element;

    if ? $text {
      $element = SemiXML::Text.new(:$text);
    }

    else {
      $element = XML::Element.new( :$name, :attribs(%$attributes));
    }

    $node.before($element);
    $element;
  }

  #-----------------------------------------------------------------------------
  sub after-element (
    XML::Element $node, Str $name = '', Hash $attributes = {}, Str :$text = ''
    --> XML::Node
  ) is export {

    my XML::Node $element;

    if ? $text {
      $element = SemiXML::Text.new(:$text);
    }

    else {
      $element = XML::Element.new( :$name, :attribs(%$attributes));
    }

    $node.after($element);
    $element;
  }

  #-----------------------------------------------------------------------------
  sub std-attrs ( XML::Element $node, Hash $attributes ) is export {

    return unless ?$attributes;

    for $attributes.keys {
      when /'class'|'style'|'id'/ {
        # attribute value must be stringified because it is now of
        # type StringList
        $node.set( $_, ~$attributes{$_});
        $attributes{$_}:delete;
      }
    }
  }

  #-----------------------------------------------------------------------------
  # Cleanup residue tags left from processing methods. The childnodes in
  # 'sxml:parent_container' tags must be moved to the parent of it. There
  # is one exception, that is when the tag is at the top. Then there may
  # only be one tag. If there are more, an error tag is generated.
  sub drop-parent-container ( XML::Element $parent ) is export {

    my $containers = $parent.elements(
      :TAG<sxml:parent_container>,
      :RECURSE, :NEST,
    );

    for @$containers -> $node {
      my $children = $node.nodes;

      # eat from the end of the list and add just after the container element.
      # somehow they get lost from the array when done otherwise.
      for @$children.reverse {
        $node.parent.after( $node, $^a);
      }

      # remove the now empty element
      $node.remove;
    }
  }

  #-----------------------------------------------------------------------------
  # search for variables and substitute them
  sub subst-variables ( XML::Element $parent ) is export {

    my XML::Document $xml-document .= new($parent);
    $parent.setNamespace( 'github.MARTIMM', 'sxml');

    # set namespace first
    my $x = XML::XPath.new(:document($xml-document));
    $x.set-namespace: 'sxml' => 'github.MARTIMM';

    # look for variable declarations
    for $x.find( '//sxml:var-decl', :to-list) -> $vdecl {
#note "\nDeclaration: $vdecl";

      # get the name of the variable
      my Str $var-name = ~$vdecl.attribs<name>;
#note "Name: $var-name";

#      # and the content of this declaration
#      my Array $var-value = $vdecl.nodes;

      # see if it is a global declaration
      my Bool $var-global = $vdecl.attribs<global>:exists;
#note "Global: $var-global";

      # now look for the variable to substitute
      my Array $var-use;
      if $var-global {
        $var-use = [ $x.find(
            '//sxml:var-ref[@name="' ~ $var-name ~ '"]', :to-list
          );
        ]
      }

      else {
        $var-use = [ $x.find(
            './/sxml:var-ref[@name="' ~ $var-name ~ '"]',
            :start($vdecl.parent), :to-list
          );
        ]
      }
#note "Search for 'sxml:var-ref[\@name=\"$var-name\"]";

      for @$var-use -> $vuse {
#note "RN P0: $vuse.parent()";
        for $vdecl.nodes -> $vdn {
          # insert cloned node just before the variable ref
          $vuse.before(clone-node( $vuse.parent, $vdn));
        }
#note "RN P1: $vuse.parent()";

        # the variable declaration is substituted in all references,
        # remove the element
        $vuse.remove;
      }

      # all variables are substituted, remove declaration too, unless it is
      # defined global. Other parts may have been untouched.
      $vdecl.remove unless $var-global;
    }

    # remove the namespace
    $parent.attribs{"xmlns:sxml"}:delete;
  }

  #-----------------------------------------------------------------------------
  # clone given node
  sub clone-node (
    XML::Element $new-parent, XML::Node $node --> XML::Node
  ) is export {

#note "  Clone parent: $new-parent.name()";
#note "  Clone the node: $node";

    my XML::Node $clone;

    # if an element must be cloned, clone everything recursively
    if $node ~~ XML::Element {

#note "  Node is an element, name: $node.name()";
      $clone = XML::Element.new( :name($node.name), :attribs($node.attribs));
      $clone.idattr = $node.idattr;

      $clone.nodes = [];
      for $node.nodes -> $n {
        $clone.append(clone-node( $clone, $n));
      }
    }

    elsif $node ~~ XML::Text {
#note "  Node is XML text";
      $clone = XML::Text.new(:text($node.text));
    }

    elsif $node ~~ SemiXML::Text {
#note "  Node is SemiXML text";
      $clone = XML::Text.new(:text($node.txt));
    }

    else {
#note "  Node is a", $node.WHAT;
      $clone = $node.cloneNode;
    }

    # set the parent right
    #$clone.parent = $new-parent;

#note "  Cloned to: $clone";
    $clone
  }

  #-----------------------------------------------------------------------------
  # move content to some other place in the document
  sub remap-content ( XML::Element $parent ) is export {

    # get xpath object
    my XML::Document $xml-document .= new($parent);
    $parent.setNamespace( 'github.MARTIMM', 'sxml');

    # set namespace first
    my $x = XML::XPath.new(:document($xml-document));
    $x.set-namespace: 'sxml' => 'github.MARTIMM';

    # look for remapping elements
    for $x.find( '//sxml:remap', :to-list) -> $remap {

      # there are 2 types;
      # map-to is used to append the content into the target xpath
      # map-after is used to insert after the target path
      my Str $map-to = $remap.attribs<map-to> // '';
      my Str $map-after = $remap.attribs<map-after> // '';

      my Str $as = $remap.attribs<as> // '';

      if ? $map-to {
        # if more nodes are found take only the first one
        my $n = $x.find( $map-to, :to-list)[0];
        die "node '$map-to' to map to, not found" unless ? $n;
        if ?$as {
          my $top-node = XML::Element.new(:name($as));
          $n.append($top-node);
          append-in( $remap, $top-node);
        }

        else {
          append-in( $remap, $n);
        }
      }

      elsif ? $map-after {
        # if more nodes are found take only the first one
        my $n = $x.find( $map-after, :to-list)[0];
        die "node '$map-after' to map after, not found" unless ? $n;
        if ?$as {
          my $top-node = XML::Element.new(:name($as));
          $n.after($top-node);
          append-in( $remap, $top-node);
        }

        else {
          append-after( $remap, $n);
        }
      }

      else {
        die "empty map-to or map-after value";
      }

      $remap.remove;
    }

    # remove the namespace
    $parent.attribs{"xmlns:sxml"}:delete;
  }

  #-----------------------------------------------------------------------------
  sub append-in ( XML::Element $from, XML::Element $in) {

    my XML::Element $hook .= new(:name('sxml:hook'));
    $in.append($hook);
    $hook.after($_) for $from.nodes.reverse;
    $hook.remove;
  }

  #-----------------------------------------------------------------------------
  sub append-after ( XML::Element $from, XML::Element $in) {

    my XML::Element $hook .= new(:name('sxml:hook'));
    $in.after($hook);
    $hook.after($_) for $from.nodes.reverse;
    $hook.remove;
  }

  #-----------------------------------------------------------------------------
  sub apply-f-table ( XML::Node $node ) is export {
    #clean-text($node);
    escape-attr-and-elements( $node, :!space-preserve, :!comment-preserve);
    check-inline($node);
  }

  #-----------------------------------------------------------------------------
  sub escape-attr-and-elements (
    XML::Node $node, Bool :$space-preserve is copy,
    Bool :$comment-preserve is copy
  ) {

    my SemiXML::Globals $globals .= instance;

    # process body text to escape special chars. we can process this always
    # because parent elements are already accepted to modify the content.
    if $node ~~ any( SemiXML::Text, XML::Text) {
      my Str $s = cleanup-text( ~$node, :$space-preserve, :$comment-preserve);
      my XML::Node $p = $node.parent;
      $p.replace( $node, SemiXML::Text.new(:text($s)));
    }

    elsif $node ~~ XML::Element {
      my Array $self-closing :=
         $globals.refined-tables<F><self-closing> // [];
      my Array $no-escaping :=
         $globals.refined-tables<F><no-escaping> // [];

      # space preservation must be kept for all inner elements as well
      $space-preserve or= (
        $globals.keep or $node.name ~~ any(
          @($globals.refined-tables<F><space-preserve> // [])
        )
      );

      $comment-preserve = $node.attribs<sxml:content> ~~ any([<B C>]);

#note "Ftab: $node.name(), ", $self-closing, ', ', $no-escaping;
      # Check for self closing tag, and if so remove content if any
      if $node.name ~~ any(@$self-closing) {
#note "$node.name() = self closing";

        # make a new empty element with the same tag-name and then remove the
        # original element.
        before-element( $node, $node.name, $node.attribs);
        $node.remove;

        # return because there are no child elements left to call recursively
        return;
      }

      else {
#note "$node.name() = not self closing";
#note "Nodes: $node.nodes.elems(), ", $node.nodes.join(', ');
        # ensure that there is at least a text element as its content
        # otherwise XML will make it self-closing
        unless $node.nodes.elems {
          append-element( $node, :text(''));
        }
#note "Nodes: $node.nodes.elems(), ", $node.nodes.join(', ');
      }

      # some elements must not be processed to escape characters
      if $node.name ~~ any(@$no-escaping) {
        # no escaping must be performed on its contents
        # for these kinds of nodes
        return;
      }

      # no processing either for nodes in the SemiXML namespace
      if $node.name ~~ m/^ 'sxml:' / {
        return;
      }

      # recursivly process through child elements
      escape-attr-and-elements(
        $_, :$space-preserve, :$comment-preserve
      ) for $node.nodes;
    }
  }

  #-----------------------------------------------------------------------------
  # Substitute some characters by XML entities, remove the remaining
  # backslashes, remove comments if possible, remove trailing spaces,
  # substitute multiple spaces by one space if possible.
  sub cleanup-text (
    Str $esc is copy, Bool :$space-preserve = False,
    Bool :$comment-preserve = False
    --> Str
  ) {

    # entity must be known in the xml result!
    $esc ~~ s:g/\& <!before '#'? \w+ ';'>/\&amp;/;
    $esc ~~ s:g/\\\s/\&nbsp;/;
    $esc ~~ s:g/ '<' /\&lt;/;
    $esc ~~ s:g/ '>' /\&gt;/;

    # remove comments only if :$comment-preserve = False
note "E0: $esc";
    $esc ~~ s:g/ \s* <!after <[\\]>> '#' \N*: $$// unless $comment-preserve;
note "E1: $esc";

    # remove backslashes
    $esc ~~ s:g/'\\'//;

    # remove leading spaces for the minimum number of spaces when the content
    # should be fixed
#note "Space: '$esc'";
    if $space-preserve {
      my Int $min-indent = 1_000_000_000;
      for $esc.lines -> $line {
        $line ~~ m/^ $<indent>=(\s*) /;
        my Int $c = $/<indent>.Str.chars;

        # adjust minimum only when there is something non-spacical on the line
        $min-indent = $c if $line ~~ m/\S/ and $c < $min-indent;
      }

      my $new-t = '';
      my Str $indent = ' ' x $min-indent;
      for $esc.lines {
        my $l = $^line;
        $l ~~ s/^ $indent//;
        $new-t ~= "$l\n";
      }

      $esc = $new-t;
    }

    else {
      # remove leading spaces at begin of text
      $esc ~~ s:g/^^ \h+ //;

      # remove trailing spaces at every line
      $esc ~~ s:g/ \h+ $$//;

      # substitute multiple spaces with one space
      $esc ~~ s:g/ \s\s+ / /;

      # remove return characters if found
      $esc ~~ s/^ \n+ //;
      $esc ~~ s/ \n+ $//;
      $esc ~~ s:g/ \n+ / /;
    }
#note "--> '$esc'";

#`{{
    # Remove rest of the backslashes unless followed by hex numbers prefixed
    # by an 'x'
    #
    if $esc ~~ m/ '\\x' <xdigit>+ / {
      my $set-utf8 = sub ( $m1, $m2) {
        return Blob.new( :16($m1.Str), :16($m2.Str)).decode;
      };

      $esc ~~ s:g/ '\\x' (<xdigit>**2) (<xdigit>**2) /{&$set-utf8( $0, $1)}/;
    }
}}

    $esc
  }

  #-----------------------------------------------------------------------------
  sub check-inline ( XML::Element $parent ) {

    my SemiXML::Globals $globals .= instance;

    # get xpath object
    my XML::Document $xml-document .= new($parent);
    $parent.setNamespace( 'github.MARTIMM', 'sxml');

    # set namespace first
    my $x = XML::XPath.new(:document($xml-document));
    $x.set-namespace: 'sxml' => 'github.MARTIMM';

    # check every element if it is an inline element. If so, check for
    # surrounding spaces.
    # first check inner text

    for $x.find( '//*', :to-list) -> $v {
      if $v.name ~~ any(@($globals.refined-tables<F><inline> // []))
         and $v.nodes.elems {
#note "CI: $v.name()";

        if $v.nodes[0] ~~ XML::Text {
          my XML::Text $t = $v.nodes[0];
          my Str $text = $t.text;
          $text ~~ s/^ \s+ //;
          $t.remove;
          $t .= new(:$text);
          $v.insert($t);
        }

        elsif $v.nodes[0] ~~ SemiXML::Text {
          my SemiXML::Text $t = $v.nodes[0];
          my Str $text = $t.txt;
          $text ~~ s/^ \s+ //;
          $t.remove;
          $t .= new(:$text);
          $v.insert($t);
        }

        elsif $v.nodes[*-1] ~~ XML::Text {
          my XML::Text $t = $v.nodes[*-1];
          my Str $text = $t.text;
          $text ~~ s/^ \s+ //;
          $t.remove;
          $t .= new(:$text);
          $v.append($t);
        }

        elsif $v.nodes[*-1] ~~ SemiXML::Text {
          my SemiXML::Text $t = $v.nodes[*-1];
          my Str $text = $t.txt;
          $text ~~ s/^ \s+ //;
          $t.remove;
          $t .= new(:$text);
          $v.append($t);
        }


        # check outer text
        my XML::Node $ps = $v.previousSibling;
        if $ps ~~ XML::Element {
          my Str $text = ~$ps;
          if $text ~~ /\S $/ {
            my XML::Text $t .= new(:text(' '));
            $v.before($t);
          }
        }

        elsif $ps ~~ XML::Text {
          my XML::Text $t := $ps;
          my Str $text = $t.text;
          $text ~= ' ';
          $t.remove;
          $t .= new(:$text);
          $v.before($t);
        }

        elsif $ps ~~ SemiXML::Text {
          my SemiXML::Text $t := $ps;
          my Str $text = $t.txt;
          $text ~= ' ';
          $t.remove;
          $t .= new(:$text);
          $v.before($t);
        }


        my XML::Node $ns = $v.nextSibling;
        if $ns ~~ XML::Element {
          my Str $text = ~$ns;
          if $text !~~ /^ <punct>/ and $text ~~ /^ \S/ {
            my XML::Text $t .= new(:text(' '));
            $v.after($t);
          }
        }

        elsif $ns ~~ XML::Text {
          my XML::Text $t := $ns;
          my Str $text = $t.text;
          if $text !~~ /^ <punct>/ and $text ~~ /^ \S/ {
            $t .= new(:text(' '));
            $v.after($t);
          }
        }

        elsif $ns ~~ SemiXML::Text {
          my SemiXML::Text $t := $ns;
          my Str $text = $t.txt;
          if $text !~~ /^ <punct>/ and $text ~~ /^ \S/ {
            $t .= new(:text(' '));
            $v.after($t);
          }
        }
      }
    }

    # remove the namespace
    $parent.attribs{"xmlns:sxml"}:delete;
  }

  #-----------------------------------------------------------------------------
  # remove leftover elements and attributes from SemiXML namespace
  sub remove-sxml ( XML::Node $node ) is export {
    my SemiXML::Globals $globals .= instance;

#note "T: $node";
    if $node ~~ XML::Element {
#note "\nE: ", $node.name;
      if $node.name ~~ m/^ sxml \: / {
        $node.remove;
        return;
      }

      else {
        for $node.attribs.keys -> $k {
          $node.unset($k) if $k ~~ m/^ sxml \: /;
          $node.unset($k) if $k ~~ m/^ xmlns \: sxml /;
        }
      }

      remove-sxml($_) for $node.nodes;
    }

    elsif $node ~~ XML::Comment {
#note "\nC: ", $node.data[*].join('; ');
      remove-sxml($_) for $node.data;
    }

    elsif $node ~~ XML::PI {
#note "\nP: ", $node.data;
      remove-sxml($_) for $node.data;
    }

    if $node ~~ XML::CDATA {
#note "\nCD: ", $node.data;
      remove-sxml($_) for $node.data;
    }


#`{{
    # get xpath object
    my XML::Document $xml-document .= new($parent);
    $parent.setNamespace( 'github.MARTIMM', 'sxml');

    # set namespace first
    my $x = XML::XPath.new(:document($xml-document));
    $x.set-namespace: 'sxml' => 'github.MARTIMM';

    # drop some leftover sxml namespace elements
    for $x.find( '//*', :to-list) -> $v {
      if $v.name() ~~ /^ 'sxml:'/ {
        note "Leftover in sxml namespace removed: '$v.name()',",
             " parent is '$v.parent.name()'"
          if $globals.trace and $globals.refined-tables<T><parse>;

        $v.remove;
      }

      else {
        for $v.attribs.keys -> $k {
          $v.unset($k) if $k ~~ m/^ sxml \: /;
        }
      }
    }

    # remove the namespace declaration
    $parent.unset("xmlns:sxml");
}}

  }
}
