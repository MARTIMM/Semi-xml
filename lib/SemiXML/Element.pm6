use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::StringList;
use SemiXML::Node;
use SemiXML::Text;
use XML;

#-------------------------------------------------------------------------------
class Element does SemiXML::Node {

  #-----------------------------------------------------------------------------
  multi submethod BUILD (
    Str:D :$!name!, SemiXML::Node :$parent, Hash :$!attributes = {}
  ) {

    # set node type
    given $!name {
      when 'sxml:cdata'   { $!node-type = SemiXML::CData; }
      when 'sxml:pi'      { $!node-type = SemiXML::PI; }
      when 'sxml:comment' { $!node-type = SemiXML::Comment; }
      default             { $!node-type = SemiXML::Plain; }
    }

    # init the rest
    $!globals .= instance;
    $!nodes = [];
    $!inline = False;
    $!noconv = False;
    $!keep = False;
    $!close = False;

    # connect to parent, root doesn't have a parent
    $parent.append(self) if ?$parent;

    # process attributes
    self!process-attributes;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD (
    Str:D :$!module!, Str:D :$!method!,
    SemiXML::Node :$parent, Hash :$!attributes = {}
  ) {

    # set node type
    $!node-type = SemiXML::Method;

    # init the rest
    $!globals .= instance;
    $!nodes = [];
    $!inline = False;
    $!noconv = False;
    $!keep = False;
    $!close = False;

    # devise a temporary name for the node
    $!name = "sxml:$!module.$!method";

    # connect to parent, root doesn't have a parent
    $parent.append(self) if ?$parent;

    # process attributes
    self!process-attributes;
  }

  #-----------------------------------------------------------------------------
  method run-method ( ) {

    # first go to inner elements
    for @$!nodes -> $node {
      $node.run-method unless $node ~~ SemiXML::Text;
    }

    # then check if node is a method node
    if $!node-type ~~ SemiXML::Method {
#note ">> $!node-type, $!body-number, $!module, $!method";

      # get the object
      my $object = self!get-object;

#note "MN 0: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ", $!parent.name;

      my Array $result = $object."$!method"(self);
      for @$result -> $node {
#note "append before $!name: $node.name()";
        # set this node's attributes on every generated node
        $node.inline = $!inline;
        $node.noconv = $!noconv;
        $node.keep = $!keep;
        $node.close = $!close;

        # and place them just before the method node
        self.before($node);
      }

      # when finished remove the method node
      self.remove;
    }
  }

  #-----------------------------------------------------------------------------
#TODO move into separate module and use with 'handles'
  # a more simple append is in the Node module. this method can not be defined
  # there because of the need of Text module.
  multi method append ( Str $name?, Hash $attributes = {}, Str :$text ) {

    # create a text element, even when it is an empty string.
    my SemiXML::Node $text-element = SemiXML::Text.new(:$text) if $text.defined;

    # create an element only when the name is defined and not empty
    my SemiXML::Node $node =
       SemiXML::Element.new( :$name, :$attributes) if ? $name;

    # if both are created than add text to the element
    if ? $node and ? $text-element {
      $node.append($text-element);
    }

    # if only text, then the element becomes the text element
    elsif ? $text-element {
      $node = $text-element;
    }

    # else $name -> no change to $element. No name and no text is an error.
#    die "No element nor text defined" unless ? $element;

    # add the node when not found and set the parent in the node
    $!nodes.push($node);
    $node.parent(self);
  }

  #-----------------------------------------------------------------------------
  method xml ( XML::Node $parent ) {
    given $!node-type {
      when any( SemiXML::Fragment, SemiXML::Plain) {
        self!plain-xml($parent);
      }

      when SemiXML::CData {
        self!cdata-xml($parent);
      }

      when SemiXML::PI {
        self!pi-xml($parent);
      }

      when SemiXML::Comment {
        self!comment-xml($parent);
      }
    }
  }

  #-----------------------------------------------------------------------------
  method Str ( Str :$text is copy = '' --> Str ) {

    for @$!nodes -> $node {
      if $node ~~ SemiXML::Text {
        $text ~= $node.text;
      }

      else {
        $text ~= $node.Str(:$text);
      }
    }

    $text
  }

  #-----------------------------------------------------------------------------
  method perl ( --> Str ) {

    my Str $e;
    my Str $modifiers = '(';
    $modifiers ~= $!inline ?? 'i ' !! '¬i '; # inline or block
    $modifiers ~= $!noconv ?? '¬e ' !! 'e '; # transform or not
    $modifiers ~= $!keep ?? 'k ' !! '¬k ';   # keep as typed or compress
    $modifiers ~= $!close ?? 's ' !! '¬s ';  # self closing or not

    $modifiers ~= '| ';

    $modifiers ~= 'F' if $!node-type ~~ SemiXML::Fragment;
    $modifiers ~= 'E' if $!node-type ~~ SemiXML::Plain;
    $modifiers ~= 'D' if $!node-type ~~ SemiXML::CData;
    $modifiers ~= 'P' if $!node-type ~~ SemiXML::PI;
    $modifiers ~= 'C' if $!node-type ~~ SemiXML::Comment;

    $modifiers ~= ')';

    my Str $attrs = '';
    for $!attributes.kv -> $k, $v {
      $attrs ~= "$k=\"$v\" ";
    }

    if $!node-type ~~ any(
       SemiXML::Plain, SemiXML::CData, SemiXML::PI, SemiXML::Comment
    ) {
      $e = [~] '$', $!name, " $modifiers", " $attrs", ' ...';
    }

    else {
      $e = [~] '$!', $!module, '.', $!method, " $modifiers", " $attrs", ' ...';
    }

    $e
  }

  #----[ private stuff ]--------------------------------------------------------
  # normal node
  method !plain-xml ( XML::Node $parent ) {

#note "$!node-type, $!body-number, $!name";
    # new xml element
    my XML::Element $xml-node .= new(:$!name);
#    self!copy-attributes($parent);
    for $!attributes.kv -> $k, $v {
      $xml-node.set( $k, ~$v);
    }

    # append node to the parent node
    $parent.append($xml-node);

    # when the node is self closing we do not need to process
    # the content of the body
    self!copy-nodes( $xml-node ) unless $!close;
  }

  #-----------------------------------------------------------------------------
  # comment node
  method !comment-xml ( XML::Node $parent ) {

#note "$!node-type, $!body-number, $!name, $parent.name()";

    my XML::Element $x .= new(:name<x>);
    self!copy-nodes( $x, :keep);
    my XML::Comment $c .= new(:data($x.nodes));

    $parent.append($c);
  }

  #-----------------------------------------------------------------------------
  # CData node
  method !cdata-xml ( XML::Node $parent ) {

#note "$!node-type, $!body-number, $!name, $parent.name()";

    my XML::Element $x .= new(:name<x>);
    self!copy-nodes( $x, :keep);
    my XML::CDATA $c .= new(:data($x.nodes));

    $parent.append($c);
  }

  #-----------------------------------------------------------------------------
  # PI node
  method !pi-xml ( XML::Node $parent ) {

#note "$!node-type, $!body-number, $!name, $parent.name()";

    my XML::Element $x .= new(:name<x>);
    self!copy-nodes( $x, :keep);
    my Str $target = ($!attributes<target> // 'no-target').Str;
    my XML::PI $c .= new(
      :data( SemiXML::XMLText.new(:text($target)), |$x.nodes)
    );

    $parent.append($c);
  }

  #-----------------------------------------------------------------------------
  method !copy-nodes ( $parent ) {

    if $!nodes.elems {
      for @$!nodes -> $node {
        $node.xml($parent);
      }
    }

    else {
      $parent.append(SemiXML::XMLText.new(:text('')));
    }
  }

  #-----------------------------------------------------------------------------
  # get the object and test for existence of method
  method !get-object ( --> Any ) {

    # get the object and test for existence of method
    my $object = $!globals.objects{$!module}
      if $!globals.objects{$!module}:exists;

    if $object.defined {
      die X::SemiXML.new(
        :message(
          "Method $!method in module $!module ($object.^name()) not defined"
        )
      ) unless $object.^can($!method);
    }

    else {
      die X::SemiXML.new(:message("Module $!module not defined"));
    }

    $object
  }
}
