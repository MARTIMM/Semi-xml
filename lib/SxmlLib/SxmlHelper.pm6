use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

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
  sub std-attrs (
    XML::Element $node, Hash $attributes
  ) is export {

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
    for $x.find( '//sxml:variable', :to-list) -> $vdecl {

      # get the name of the variable
      my Str $var-name = ~$vdecl.attribs<name>;

      # and the content of this declaration
      my @var-value = $vdecl.nodes;

      # see if it is a global declaration
      my Bool $var-global = $vdecl.attribs<global>:exists;

      # now look for the variable to substitute
      my @var-use;
      if $var-global {
        @var-use = $x.find( '//sxml:' ~ $var-name, :to-list);
      }

      else {
#note "Parent: $vdecl.parent()";
#note "search for './/sxml:$var-name'";
        @var-use = $x.find(
          './/sxml:' ~ $var-name, :start($vdecl.parent), :to-list
        );
      }

      for @var-use -> $vuse {
        for $vdecl.nodes -> $vdn {
          my XML::Node $x = clone-node($vdn);
          $vuse.parent.before( $vuse, $x);
        }

        # the variable is substituted, remove the element
        $vuse.remove;
      }

      # all variable are substituted, remove declaration too, unless it is
      # defined global. Other parts may have been untouched.
      $vdecl.remove unless $var-global;
    }

    # remove the namespace
    $parent.attribs{"xmlns:sxml"}:delete;
  }

  #-----------------------------------------------------------------------------
  sub clone-node ( XML::Node $node --> XML::Node ) is export {

    my XML::Node $clone;

    if $node ~~ XML::Element {

#note "Node is element, name: $node.name()";
      $clone = XML::Element.new( :name($node.name), :attribs($node.attribs));
      $clone.idattr = $node.idattr;

      $clone.nodes = [];
      for $node.nodes -> $n {
        $clone.nodes.push: clone-node($n);
      }
    }

    elsif $node ~~ XML::Text {
#note "Node is text";
      $clone = XML::Text.new(:text($node.text));
    }

    elsif $node ~~ SemiXML::Text {
#note "Node is text";
      $clone = SemiXML::Text.new(:text($node.txt));
    }

    else {
#note "Node is ", $node.WHAT;
      $clone = $node.cloneNode;
    }

#note "Clone: ", $clone.perl;
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
          $top-node.append(clone-node($_)) for $remap.nodes;
          $n.append($top-node);
        }

        else {
          $n.append(clone-node($_)) for $remap.nodes;
        }
      }

      elsif ? $map-after {
        # if more nodes are found take only the first one
        my $n = $x.find( $map-after, :to-list)[0];
        die "node '$map-after' to map after, not found" unless ? $n;
        if ?$as {
          my $top-node = XML::Element.new(:name($as));
          $top-node.append(clone-node($_)) for $remap.nodes;
          $n.after($top-node);
        }

        else {
          my XML::Element $hook = after-element( $n, 'sxml:hook');
          $hook.before(clone-node($_)) for $remap.nodes;
          $hook.remove;
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
  my $local-action;
  sub escape-attr-and-elements (
    XML::Element $x,
    $action is copy where .^name eq 'SemiXML::Actions' = $local-action
  ) is export {

    # when called from Action $action is set, otherwise it was from the
    # recursive call. this saves some stack space.
    $local-action = $action if ?$action;

    # process body text to escape special chars
    for $x.nodes -> $node {

      if $node ~~ any( SemiXML::Text, XML::Text) {
        my Str $s = process-esc(~$node);
        $node.parent.replace( $node, SemiXML::Text.new(:text($s)));
      }

      elsif $node ~~ XML::Element {
        my Array $self-closing = $action.F-table<self-closing> // [];
        my Array $no-escaping = $action.F-table<no-escaping> // [];

#note "Ftab: $node.name()", $self-closing, $no-escaping;
        # Check for self closing tag, and if so remove content if any
        if $node.name ~~ any(@$self-closing) {
          before-element( $node, $node.name, $node.attribs);
          $node.remove;
          next;
        }

        else {
          # ensure that there is at least a text element as its content
          # otherwise XML will make it self-closing
          unless $node.nodes.elems {
            append-element( $node, :text(''));
          }
        }

        # some elements mast not be processed to escape characters
        if $node.name ~~ any(@$no-escaping) {
          # no escaping must be performed on its contents
          # for these kinds of nodes
          next;
        }

        # no processing for these kinds of nodes
        if $node.name ~~ m/^ 'sxml:' / {
          next;
        }

        # recurively process through other type of elements
        escape-attr-and-elements($node);

#        # If this is not a self closing element and there is no content, insert
#        # an empty string to get <a></a> instead of <a/>
#        if ! $node.nodes {
#          $node.append(SemiXML::Text.new(:text('')));
#        }
      }

#        elsif $node ~~ any(XML::Text|SemiXML::Text) {
#
#        }
    }
  }

  #-----------------------------------------------------------------------------
  # Substitute some escape characters in entities and remove the remaining
  # backslashes.
  sub process-esc ( Str $esc is copy --> Str ) {

    # Entity must be known in the xml result!
    $esc ~~ s:g/\& <!before '#'? \w+ ';'>/\&amp;/;
    $esc ~~ s:g/\\\s/\&nbsp;/;
    $esc ~~ s:g/ '<' /\&lt;/;
    $esc ~~ s:g/ '>' /\&gt;/;

    $esc ~~ s:g/'\\'//;

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

    return $esc;
  }

  #-----------------------------------------------------------------------------
  # remove leftovers from sxml namespace
  sub remove-sxml ( XML::Element $parent ) is export {

    # get xpath object
    my XML::Document $xml-document .= new($parent);
    $parent.setNamespace( 'github.MARTIMM', 'sxml');

    # set namespace first
    my $x = XML::XPath.new(:document($xml-document));
    $x.set-namespace: 'sxml' => 'github.MARTIMM';

    # drop some leftover sxml namespace elements
    for $x.find( '//*', :to-list) -> $v {
      if $v.name() ~~ /^ 'sxml:'/ {
        note "Leftover in sxml namespace removed: '$v.name()', parent is '$v.parent.name()'";
        $v.remove;
      }
    }

    # remove the namespace
    $parent.attribs{"xmlns:sxml"}:delete;
  }
}
