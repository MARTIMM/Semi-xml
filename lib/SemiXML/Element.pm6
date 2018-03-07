use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::StringList;
use SemiXML::Node;
use SemiXML::Text;

#-------------------------------------------------------------------------------
class Element does SemiXML::Node {

  my Hash $var-declarations;

  #-----------------------------------------------------------------------------
  multi submethod BUILD (
    Str:D :$!name!, SemiXML::Element :$parent is copy, Hash :$!attributes = {}
  ) {

    # init
    $!globals .= instance;
    $!nodes = [];
    $!inline = False;
    $!noconv = False;
    $!keep = False;
    $!close = False;

    $var-declarations //= {};

    # set node type and modify for special nodes
    given $!name {
      when 'sxml:cdata' {
        $!node-type = SemiXML::NTCData;
      }

      when 'sxml:pi' {
        $!node-type = SemiXML::NTPI;
      }

      when 'sxml:comment' {
        $!node-type = SemiXML::NTComment;
        $!keep = True;
      }

      when 'sxml:xml' {
        $!node-type = SemiXML::NTXml;
      }

      # store all declarations
      when 'sxml:var-decl' {
note "Decl: $!name, ", $var-declarations.keys, ', ', $!attributes.keys;
        $!node-type = SemiXML::NTVDecl;
        $var-declarations{~$!attributes<name>} = self if $!attributes<name>;
      }

      # insert before reference all nodes from declaration
      when 'sxml:var-ref' {
note "Ref: $!name, ", $!attributes.keys(), ", ", $var-declarations.keys;
        # no processing here. when declarations are generated by an external
        # method, the references appear before the declarations are stored.
        # this meabs that processing is deferred to the moment xml
        # is generated.
        $!node-type = SemiXML::NTVRef;
      }

      default {
        $!node-type = SemiXML::NTElement;
      }
    }

    # every node should have a parent except for the parents themselves. so,
    # if not defined, create a stand-in.
#    $parent .= new(:name<sxml:parent>)
#      unless $parent or $!name eq 'sxml:parent';

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

#TODO what to do when same element appears twice from same object
    # initialize objects top down
    if $!node-type ~~ SemiXML::NTMethod {
      # get the object
      my $object = self!get-object;
      $object.initialize(self) if $object.^can('initialize');
    }

    # go to inner elements until we reach a leaf
    for @$!nodes -> $node {
      $node.run-method unless $node ~~ SemiXML::Text;
    }

    # then from leaf back to top, check if node is a method node
    if $!node-type ~~ SemiXML::NTMethod {

      # get the object
      my $object = self!get-object;


      # call the objects method. the method must insert its data into the tree
      $object."$!method"(self);

      # when finished remove the method node and children
      # keep the parent object
      my SemiXML::Node $parent = $!parent;

      # remove this method object from parent
      $parent.remove-child(self);
    }
  }

  #-----------------------------------------------------------------------------
  # set attributes
  multi method attributes ( Hash:D $attributes, :$modify = False ) {

note "Attr $!name, ", $!attributes;
    if $!name eq 'sxml:var-decl' and $!attributes<name>:exists {
note "Set attr $!name";
      $var-declarations{~$!attributes<name>} = self;
    }

    # continue processing in Node class
    callsame;
  }

  #-----------------------------------------------------------------------------
  # more methods like append are in the Node module. this method can not
  # be defined there because of the need of class Element and Text which
  # will create circular reference errors when defined in Node.
  multi method append (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    my SemiXML::Node $node = self!make-node-with-text(
      $name, :$attributes, :$text, :operation<append>
    );
  }

  #-----------------------------------------------------------------------------
  multi method insert (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    self!make-node-with-text( $name, :$attributes, :$text, :operation<insert>);
  }

  #-----------------------------------------------------------------------------
  multi method before (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    self!make-node-with-text( $name, :$attributes, :$text, :operation<before>);
  }

  #-----------------------------------------------------------------------------
  multi method after (
    Str $name?, Hash :$attributes = {}, Str :$text
    --> SemiXML::Node
  ) {

    self!make-node-with-text( $name, :$attributes, :$text, :operation<after>);
  }

  #-----------------------------------------------------------------------------
  # clone given node
  method clone-node ( --> SemiXML::Node ) {

    my SemiXML::Node $clone;

    # create a clone from this node and add its attributes
    if $!node-type ~~ SemiXML::NTMethod {
      $clone = SemiXML::Element.new( :$!module, :$!method, :$!attributes);
    }

    else {
      $clone = SemiXML::Element.new( :$!name, :$!attributes);
    }

    $clone.inline = $!inline;
    $clone.keep = $!keep;
    $clone.close = $!close;
    $clone.noconv = $!noconv;

    # recursivly clone all child nodes
    for @$!nodes -> $n {
      # clone this nodes child node and append node to its new parent clone
      $clone.append($n.clone-node);
    }

    $clone
  }

  #-----------------------------------------------------------------------------
  method xml ( --> Str ) {

    my Str $xml-text;
    given $!node-type {
      when any( SemiXML::NTFragment, SemiXML::NTElement, SemiXML::NTMethod) {
        $xml-text = self!plain-xml;
      }

      when SemiXML::NTCData {
        $xml-text = self!cdata-xml;
      }

      when SemiXML::NTPI {
        $xml-text = self!pi-xml;
      }

      when SemiXML::NTComment {
        $xml-text = self!comment-xml;
      }

      when SemiXML::NTXml {
        $xml-text = self!xml-xml;
      }

      when SemiXML::NTVDecl {
        # entries are not translated
        if $!globals.raw {
          $xml-text = self!plain-xml;
        }

        else {
          $xml-text = '';
        }
      }

      when SemiXML::NTVRef {
        if $!globals.raw {
          $xml-text = self!plain-xml;
        }

        else {
note "VR: $!name, $!parent.name(), $!attributes<name>, ", $!attributes.keys, ', ', $var-declarations.keys;
          $xml-text = ' ';
          my SemiXML::Element $vdecl =
            $var-declarations{~$!attributes<name>} // SemiXML::Element;
          if $vdecl.defined {
            for $vdecl.nodes -> $node {
              $xml-text ~= $node.xml;
            }

            $xml-text ~= ' ';
          }
        }
      }

      default {
        $xml-text = '';
      }
    }

    $xml-text
  }

  #-----------------------------------------------------------------------------
  method Str ( Str $t is copy = '', Int $l = 0 --> Str ) {

    $t = $t ~ ( "\n" ~
                self.perl(:simple) ~
                "[" ~ ($!nodes.elems ?? "\n" !! '')
              ).indent($l);

    for @$!nodes -> $node {
      given $node {
        when SemiXML::Text {
          $t ~= $node.Str.indent($l + 2);
        }

        default {
          $t = $node.Str( $t, $l + 2);
        }
      }
    }

    $t ~= ($!nodes.elems ?? "\n" !! '') ~ "]".indent($l);

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
      $modifiers ~= 'C' if $!node-type ~~ SemiXML::NTComment;
      $modifiers ~= 'V' if $!node-type ~~ SemiXML::NTVDecl;
      $modifiers ~= 'R' if $!node-type ~~ SemiXML::NTVRef;

      $modifiers ~= ')';
    }

    my Str $attrs = ' ';
    for $!attributes.kv -> $k, $v {
      $attrs ~= "$k=\"$v\" ";
    }

    if $!node-type ~~ any(
       SemiXML::NTElement, SemiXML::NTCData, SemiXML::NTPI, SemiXML::NTComment,
       SemiXML::NTVDecl, SemiXML::NTVRef
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
        $xml-text ~= $node.xml // '';
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

    my Str $target = ($!attributes<target>:delete // 'no-target').Str;
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

  #-----------------------------------------------------------------------------
  # Xml node
  method !xml-xml ( --> Str ) {

#TODO $attributes<to-sxml> reverse engineer xml to sxml

    my Str $xml-text = '';
    for @$!nodes -> $node {
      $xml-text ~= $node.xml;
    }

    $xml-text
  }

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
  # make a node without a parent. add text if defined. return text only
  # if name is not defined
  method !make-node-with-text(
    Str $name?, Hash :$attributes = {}, Str :$text, Str:D :$operation
    --> SemiXML::Node
  ) {

    # create a parent for element and text node. remove when reparented
    my SemiXML::Element $parent .= new( :name<sxml:parent>, :$attributes);

    # create a text element, even when it is an empty string.
    my SemiXML::Text $text-element =
       SemiXML::Text.new( :$text, :$parent) if $text.defined;

    # create an element only when the name is defined and not empty
    my SemiXML::Node $node =
       SemiXML::Element.new( :$name, :$attributes, :$parent) if ? $name;

    # if both are created than add text to the element
    if ? $node and ? $text-element {
      $node.append($text-element);
    }

    # if only text, then the element becomes the text element
    elsif ? $text-element {
      $node = $text-element;
    }

    # at last move the node from the fake parent to 'before', 'after',
    # 'append' or 'insert'. undefine the parent after that.
#note "\nMNWT 0: $!name\.$operation, $node.name(), $parent";

    self."$operation"($node);
    $parent = Nil;

#note "MNWT 1: $!name\.$operation, $node.parent()";
#note ' ';

    $node
  }

  #-----------------------------------------------------------------------------
  # get the object and test for existence of method
  method !get-object ( --> Any ) {

    # get the object and test for existence of method
    my Hash $objects = $!globals.objects;
    my $object = $objects{$!module} if $objects{$!module}:exists;

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
