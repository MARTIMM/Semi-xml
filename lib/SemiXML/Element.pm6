use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::StringList;
use SemiXML::Node;
use SemiXML::Text;

#-------------------------------------------------------------------------------
class Element does SemiXML::Node {

  #-----------------------------------------------------------------------------
  multi submethod BUILD (
    Str:D :$!name!, SemiXML::Node :$parent, Hash :$!attributes = {}
  ) {

    # init
    $!globals .= instance;
    $!nodes = [];
    $!inline = False;
    $!noconv = False;
    $!keep = False;
    $!close = False;

    # set node type and modify for special nodes
    given $!name {
      when 'sxml:cdata' {
        $!node-type = SemiXML::NTCData;
        $!keep = $!noconv = True;
      }

      when 'sxml:pi' {
        $!node-type = SemiXML::NTPI;
        $!keep = $!noconv = True;
      }

      when 'sxml:comment' {
        $!node-type = SemiXML::NTComment;
        $!keep = True;
      }

      default {
        $!node-type = SemiXML::NTElement;
      }
    }

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
    $!node-type = SemiXML::NTMethod;

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

    # finitialize object top down
    if $!node-type ~~ SemiXML::NTMethod {
      # get the object
      my $object = self!get-object;
      $object.initialize(self) if $object.^can('initialize');
    }

    # go to inner elements until we reach a leaf
    for @$!nodes -> $node {
      $node.run-method unless $node ~~ SemiXML::Text;
    }

#note "rm 0 $!name, $!node-type, $!body-number";
    # then from leaf back to top, check if node is a method node
    if $!node-type ~~ SemiXML::NTMethod {
#note "rm 1 $!module, $!method";

      # get the object
      my $object = self!get-object;

#note "MN 0: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ", $!parent.name;

      # call the objects method. the method must insert its data into the tree
      $object."$!method"(self);
#`{{
      $!nodes = [ |@$!nodes, |@($object."$!method"(self) // [])];
      for @$!nodes.reverse -> $node {

        # assume that the top level nodes do not have a parent
        # with this the nodes become the methods children
        $node.parent(self);

#note "\nappend before $!name: $node.name()\n$node";
        # set this node's attributes on every generated node
        $node.inline = $!inline;
        $node.noconv = $!noconv;
        $node.keep = $!keep;
        $node.close = $!close;

        # and place them just before the method node
        self.after($node);
      }
}}

      # when finished remove the method node and children
      # keep the parent object
      my SemiXML::Node $parent = $!parent;
#`{{
      # define a sub to do job recursively
      sub rm-node ( $n ) {
#note "rm $n.name()";
        unless $n ~~ SemiXML::Text {
          for $n.nodes -> $node is rw {
            # first go deep
            rm-node($node);
            $node.parent(:undef);
          }

          $n.undef-nodes;
        }

        $n.parent(:undef);
      }

      # call sub
      rm-node(self);
}}
      # remove this method object from parent
      $parent.remove-child(self);
#note "after inserting before:\n", $parent.Str;
    }
  }

  #-----------------------------------------------------------------------------
  # more simple methods like append are in the Node module. this method
  # can not be defined there because of the need of Element and Text module
  # which will create circular reference errors when defined in Node.
  multi method append (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    my SemiXML::Node $node = self!make-node-with-text(
      $name, :$attributes, :$text
    );

    $!nodes.push($node);
    $node.parent(self);

    $node
  }

  #-----------------------------------------------------------------------------
  multi method insert (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    my SemiXML::Node $node = self!make-node-with-text(
      $name, :$attributes, :$text
    );

    $!nodes.unshift($node);
    $node.parent(self);

    $node
  }

  #-----------------------------------------------------------------------------
  multi method before (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    my SemiXML::Node $node = self!make-node-with-text(
      $name, :$attributes, :$text
    );

    $node.before(self);

    $node
  }

  #-----------------------------------------------------------------------------
  multi method before (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    my SemiXML::Node $node = self!make-node-with-text(
      $name, :$attributes, :$text
    );

    $node.after(self);

    $node
  }

  #-----------------------------------------------------------------------------
  method !make-node-with-text(
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    # create a text element, even when it is an empty string.
    my SemiXML::Text $text-element = SemiXML::Text.new(:$text) if $text.defined;

    # create an element only when the name is defined and not empty
    my SemiXML::Node $node =
       SemiXML::Element.new( :$name, :$attributes) if ? $name;

#note "H: {$node//'-'}, T: $text-element";

    # if both are created than add text to the element
    if ? $node and ? $text-element {
      $node.append($text-element);
    }

    # if only text, then the element becomes the text element
    elsif ? $text-element {
      $node = $text-element;
    }

    $node
  }

  #-----------------------------------------------------------------------------
  #method xml ( XML::Node $parent ) {
  method xml ( --> Str ) {

    my Str $xml-text = '';
    given $!node-type {
      when any( SemiXML::NTFragment, SemiXML::NTElement, SemiXML::NTMethod) {
        $xml-text ~= self!plain-xml;
      }

      when SemiXML::NTCData {
        $xml-text ~= self!cdata-xml;
      }

      when SemiXML::NTPI {
        $xml-text ~= self!pi-xml;
      }

      when SemiXML::NTComment {
        $xml-text ~= self!comment-xml;
      }
    }

    $xml-text
  }

  #-----------------------------------------------------------------------------
  my Str $t = '';
  method Str ( Int :$l is copy --> Str ) {

    unless $l {
      $t = '';
      $l = 0;
    }

    $t = $t ~ (self.perl(:simple) ~ " [\n").indent($l);

    for @$!nodes -> $node {
      given $node {
        when SemiXML::Text {
          my $tnode = ($node.Str ~ "\n").indent($l);
          $t ~= $tnode if $tnode ~~ m/ \S /;
        }

        default {
          $node.Str(:l($l + 2));
        }
      }
    }

    $t ~= "]\n".indent($l);

    $t
  }

  #-----------------------------------------------------------------------------
  method perl ( Bool :$simple = False --> Str ) {

    my Str $e;
    my Str $modifiers;

    if $simple {
      $modifiers = '';
    }

    else {
      $modifiers = ' (';
      $modifiers ~= $!inline ?? 'i ' !! '¬i '; # inline or block
      $modifiers ~= $!noconv ?? '¬t ' !! 't '; # transform or not
      $modifiers ~= $!keep ?? 'k ' !! '¬k ';   # keep as typed or compress
      $modifiers ~= $!close ?? 's ' !! '¬s ';  # self closing or not

      $modifiers ~= '| ';

      $modifiers ~= 'F' if $!node-type ~~ SemiXML::NTFragment;
      $modifiers ~= 'E' if $!node-type ~~ SemiXML::NTElement;
      $modifiers ~= 'D' if $!node-type ~~ SemiXML::NTCData;
      $modifiers ~= 'P' if $!node-type ~~ SemiXML::NTPI;
      $modifiers ~= 'C' if $!node-type ~~ SemiXML::NTPI;

      $modifiers ~= ')';
    }

    my Str $attrs = ' ';
    for $!attributes.kv -> $k, $v {
      $attrs ~= "$k=\"$v\" ";
    }

    if $!node-type ~~ any(
       SemiXML::NTElement, SemiXML::NTCData, SemiXML::NTPI, SemiXML::NTPI
    ) {
      $e = [~] '$', $!name, $modifiers, $attrs;
    }

    else {
      $e = [~] '$!', $!module, '.', $!method, $modifiers, $attrs;
    }

    $e ~= ' ... ' unless $simple;

    $e
  }

  #----[ private stuff ]--------------------------------------------------------
  # normal node
  method !plain-xml ( --> Str ) {

    # return when we encounter an sxml namespace node. these are not translated
    # except for the top fragment node or when option raw is true
    return '' if $!name ~~ m/^ sxml ':' /
              and $!name ne 'sxml:fragment'
              and !$!globals.raw;

    # xml name and attributes
    my Str $xml-text = "<$!name";
    for $!attributes.keys.sort -> $key {

      # filter out sxml namespace attributes
      next if $key ~~ m/^ sxml ':' / and !$!globals.raw;

      # get value and convert doube quotes
      my Str $value = $!attributes{$key}.Str;
      $value ~~ s:g/ '"' /\&quot;/;
      $xml-text ~= Q:qq| $key="$value"|;
    }

    # show option when raw and close to show that children are removed
    $xml-text ~= ' sxml:close="1"' if $!close and $!globals.raw;

    # check if self closing
    if $!close {
      $xml-text ~= '/>';
    }

    else {
      $xml-text ~= '>';

      for @$!nodes -> $node {
        $xml-text ~= $node.xml;
      }

      $xml-text ~= "</$!name>";
    }

    $xml-text
  }

  #-----------------------------------------------------------------------------
  # comment node
#TODO things go wrong when comments are nested
  method !comment-xml ( --> Str ) {

    my Str $xml-text = '<!--';
    for @$!nodes -> $node {
      $xml-text ~= $node.xml;
    }

    $xml-text ~= '-->'
  }

  #-----------------------------------------------------------------------------
  # CData node
  method !cdata-xml ( --> Str ) {

    my Str $xml-text = '<![CDATA[';
    for @$!nodes -> $node {
      $xml-text ~= $node.xml;
    }

    $xml-text ~= ']]>'
  }

  #-----------------------------------------------------------------------------
  # PI node
  method !pi-xml ( --> Str ) {

    my Str $target = ($!attributes<target> // 'no-target').Str;
    my Str $xml-text = "<?$target";
    for $!attributes.keys.sort -> $key {
      # filter out sxml namespace attributes
      next if $key ~~ m/^ sxml ':' / and !$!globals.raw;

      my Str $value = $!attributes{$key}.Str;
      $value ~~ s:g/ '"' /\&quot/;
      $xml-text ~= Q:qq| $key="$value"|;
    }

    if $!nodes.elems {
      $xml-text ~= "\n";
      for @$!nodes -> $node {
        $xml-text ~= $node.xml;
      }
      $xml-text ~= "\n";
    }

    $xml-text ~= '?>'
  }

#`{{
  #-----------------------------------------------------------------------------
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
      :data( SemiXML::Text.new(:text($target)), |$x.nodes)
    );

    $parent.append($c);
  }
}}

  #-----------------------------------------------------------------------------
  method !copy-nodes ( $parent ) {

    if $!nodes.elems {
      for @$!nodes -> $node {
        $node.xml($parent);
      }
    }

    else {
      $parent.append(SemiXML::Text.new(:text('')));
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

#`{{
  #-----------------------------------------------------------------------------
  # $element<<text>> is like $element.append(SemiXML::Text.new('text'))
  multi sub postcircumfix:<( )>(
  SemiXML::Element:D $element, Str:D $text
  #  --> SemiXML::Text
  ) {

    note "« »: $element.name(), $text";
    #  $element.append(SemiXML::Text.new(:$text));
    #  $element.nodes[*-1];
  }
}}
}
