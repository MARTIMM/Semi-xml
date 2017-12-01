use v6;

#------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Text;
use XML;
use XML::XPath;

#------------------------------------------------------------------------------
class SxmlHelper {

  #----------------------------------------------------------------------------
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

  #----------------------------------------------------------------------------
  sub append-element (
    XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text = ''
    --> XML::Node
  ) is export {

    my XML::Node $text-element = SemiXML::Text.new(:$text) if ? $text;
    my XML::Node $element =
       XML::Element.new( :$name, :attribs(%$attributes)) if ? $name;

    if ? $element and ? $text-element {
      $element.append($text-element);
    }

    elsif ? $text-element {
      $element = $text-element;
    }

    # else $name -> no change to $element. No name and no text is an error.

    $parent.append($element);
    $element;
  }

  #----------------------------------------------------------------------------
  sub insert-element (
    XML::Element $parent, Str $name = '', Hash $attributes = {}, Str :$text = ''
    --> XML::Node
  ) is export {

    my XML::Node $element;

    if ? $text {
      $element = SemiXML::Text.new(:$text);
    }

    else {
      $element = XML::Element.new( :$name, :attribs(%$attributes));
    }

    $parent.insert($element);
    $element;
  }

  #----------------------------------------------------------------------------
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

  #----------------------------------------------------------------------------
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

  #----------------------------------------------------------------------------
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

  #---------------------------------------------------------------------------
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
}
