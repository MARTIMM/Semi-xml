use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Node;
use SemiXML::Element;
use SemiXML::Text;
use SemiXML::StringList;

#-------------------------------------------------------------------------------
class Actions {

  has SemiXML::Globals $!globals;

  # the root should only have one element. when there are more, convert
  # the result into a fragment.
  has SemiXML::Element $.root;

  # array of element showing the path to the currently parsed element. therefore
  # an element in the array will always be the parent of the one next to it.
  has Array $!elements;
  has Int $!element-idx;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!globals .= instance;
  }

  #-----------------------------------------------------------------------------
  method TOP ( $match ) {

    # initialize root node and place in the array. this node will never be
    # overwritten.
    $!root .= new(
      :name<sxml:fragment>,
      :attributes({'xmlns:sxml' => 'https://github.com/MARTIMM/Semi-xml'})
    );
    $!elements = [$!root];
    $!element-idx = 1;

#note "\nAt the end of parsing";
    # process the result tree
    self!process-ast($match);

    # execute any method bottom up and generate sxml structures
    $!root.run-method if $!globals.exec;
#note "NTop Tree F=$!globals.frag(), \n$!root.Str()";

    unless $!globals.raw {
#      $!root.subst-variables;
#        self!remap-content($root-xml);

      # remove all tags from the sxml namespace.
      #self!remove-sxml-namespace($!root);
#note "NTop 2d: $root-xml";
    }
  }

  #-----------------------------------------------------------------------------
  # always perform xml transforms when asked for xml-text
  method xml-text ( ) {

    my Str $xml-text = '';
    if $!root.nodes.elems == 0 {
      $xml-text = $!root.xml;
    }

    elsif $!root.nodes.elems == 1 {
      self!set-namespaces($!root.nodes[0]);
      $xml-text = $!root.nodes[0].xml;
    }

    elsif $!root.nodes.elems > 1 {
      if $!globals.frag {
        self!set-namespaces($!root.nodes[0]);
        $xml-text = $!root.xml;
      }

      else {
        die X::SemiXML.new(
          :message(
            "Too many nodes on top level. Maximum allowed nodes is one"
          )
        )
      }
    }
  }

  #-----------------------------------------------------------------------------
  # always perform xml transforms when asked for xml-text
  method root-name ( --> Str ) {

    my $root-name = '';
    if $!root.nodes.elems == 0 {
      $root-name = $!root.name;
    }

    elsif $!root.nodes.elems == 1 {
      $root-name = $!root.nodes[0].name;
    }

    elsif $!root.nodes.elems > 1 {
      if $!globals.frag {
        $root-name = $!root.name;
      }

      else {
        die X::SemiXML.new(
          :message(
            "Too many nodes on top level. Maximum allowed nodes is one"
          )
        )
      }
    }

    $root-name
  }

  #-----------------------------------------------------------------------------
  # set the result sxml
  multi method sxml-tree ( SemiXML::Node:D :$sxml-tree! ) {

    $!root .= new(:name<sxml:fragment>);
    $!root.append($sxml-tree);
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # reverse engineer from xml to sxml tree
  multi method sxml-tree ( SemiXML::Node:D :$xml! ) {

    sub cnvnodes ( SemiXML::Node $parent ) {
      for $parent.nodes -> $node {
        when SemiXML::Element {
        }

        when SemiXML::Text {
        }

        default {
        }
      }
    }

    $!root .= new(:name<sxml:fragment>);

  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # reverse engineer from xml to sxml tree
  multi method sxml-tree ( Str:D :$xml-text! ) {
#    my XML::Document $xml = from-xml-file($xml-text);
#    self.sxml-tree(:xml($xml.root));
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # get the result sxml
  multi method sxml-tree ( --> SemiXML::Node ) {

    my SemiXML::Node $sxml-tree;
    if $!root.nodes.elems == 0 {
      $sxml-tree = $!root;
    }

    elsif $!root.nodes.elems == 1 {
      $sxml-tree = $!root.nodes[0];
      $sxml-tree.parent(SemiXML::Element.new(:name<X>));
    }

    elsif $!root.nodes.elems > 1 {
      if $!globals.frag {
        $sxml-tree = $!root;
      }

      else {
        die X::SemiXML.new(
          :message( "Too many nodes on top level. Maximum allowed nodes is one")
        )
      }
    }

    $sxml-tree
  }

#`{{
  #-----------------------------------------------------------------------------
  # messages
  method tag-spec ( $match ) { self!make-note( $match, 'tag-spec'); }
  method body-a ( $match ) { self!make-note( $match, 'body-a'); }
  method body-b ( $match ) { self!make-note( $match, 'body-b'); }
  method body-c ( $match ) { self!make-note( $match, 'body-c'); }
  #method  ( $match ) {
  #method  ( $match ) {

  method !make-note ( $match, $routine-name ) {
    note "$routine-name: $match"
      if $!globals.trace and $!globals.refined-tables<T><parse>;
  }
}}
  #----[ private stuff ]--------------------------------------------------------
  method !process-ast ( Match $m, Int $l = 0 ) {

    # do not go deeper into the tree after having processed some parts via
    # other calls
    my Bool $prune = False;

    for $m.caps -> Pair $pair ( :key($k), :value($v)) {

      if $!globals.trace and $!globals.refined-tables<T><parse> {
        unless $k ~~ any(<sym tag-name element attribute attr-key attr-value
                          attr-value-spec bool-true-attr bool-false-attr
                          pre-body
                        >) {
          my Str $value-text = $k ~~ any(<tag-bodies document>)
                 ?? ( $v ~~ m/ \n / ?? " ... " !! $v.Str )
                 !! $v.Str;
          note "$k: '$value-text'".indent($l);
        }
      }

      given $k {
        when 'tag' {
          my SemiXML::Element $element = self!create-element(
            $v, $!elements[$!element-idx - 1]
          );
          $!elements[$!element-idx] = $element;
          #$!elements[$!element-idx - 1].append($element);

          note ("--> Append element: $element.name() to " ~
                "$!elements[$!element-idx - 1].name()").indent($l)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'attributes' {
          my SemiXML::Element $element = $!elements[$!element-idx];
          $element.attributes(self!attributes([$v.caps]));
#note "Idx B: $!element-idx, $element.name(), $v.caps()";

          note "--> Created element: $element.perl()".indent($l)
            if $!globals.trace and $!globals.refined-tables<T><parse>;

          # note that bodies must use 'index - 1' because of the
          # index of the elements array is now incremented
          $!element-idx++;
#note "Idx B: $!element-idx";
        }

        when 'tag-bodies' {

          my Str $pre-body = self!process-bodies(
            $!elements[$!element-idx - 1], [$v.caps], $l + 2
          );

          # prune the rest because recursive calls are made from
          # process-bodies() when a document is encountered
          $prune = True;

          # also don't bring this line before the call because
          # of the same reasons.
          $!element-idx--;
#note "Idx C: $!element-idx";

          if ?$pre-body {
            # to insert the space we must select the element just one lower on
            # the stack of elements
            my SemiXML::Element $element = $!elements[$!element-idx - 1];
            my SemiXML::Text $t .= new(
              :text($pre-body.Str), :parent($element)
            );
            $t.body-type = SemiXML::BTBodyC;  # dont care really, only spaces
            $t.body-number = $element.body-count;
            #$element.append($t);

            my $v1 = $v;
            $v1 ~~ s:g/ \n /\\n/;
            note ("[$element.body-count()] --> moved down and append '$v1'" ~
                  " to $element.name()").indent(max(0,$l-4))
              if $!globals.trace and $!globals.refined-tables<T><parse>;
          }
        }
      }

      self!process-ast( $v, $l + 2) unless $prune;
    }
  }

  #-----------------------------------------------------------------------------
  method !create-element (
    Match $tag, SemiXML::Node $parent
    --> SemiXML::Element
  ) {

    my SemiXML::Element $element;

    my Str $symbol = $tag<sym>.Str;
    if $symbol eq '$' {
      $element .= new( :name($tag<tag-name>.Str), :$parent);
    }

    elsif $symbol eq '$!' {
      $element .= new(
        :module($tag<mod-name>.Str), :method($tag<meth-name>.Str), :$parent
      );
    }

    $element
  }

  #-----------------------------------------------------------------------------
  method !attributes ( Array $attr-specs --> Hash ) {

    # define the attributes for the element. attr value is of type StringList
    # where ~$strlst gives string, @$strlst returns list and $strlist.value
    # either string or list depending on :use-as-list which in turn depends
    # on the way an attribute is defined att='val1 val2' or att=<val1 val2>.
    my Hash $attrs = {};
    for @$attr-specs -> $as {

      next unless $as<attribute>:exists;
      my $a = $as<attribute>;
      my SemiXML::StringList $av;

      # when =attr is same as attr=1
      if ? $a<bool-true-attr> {
        $av .= new( :string<1>, :!use-as-list);
      }

      # when =!attr is same as attr=0
      elsif ? $a<bool-false-attr> {
        $av .= new( :string<0>, :!use-as-list);
      }

      else {
        # when attr=<a b c> attr-list-value is set
        $av .= new(
          :string($a<attr-value-spec><attr-value>.Str),
          :use-as-list(?($a<attr-value-spec><attr-list-value> // False))
        );
      }

      $attrs{$a<attr-key>.Str} = $av;
    }

    $attrs;
  }

  #-----------------------------------------------------------------------------
  method !process-bodies (
    SemiXML::Element $element, Array $body-specs, Int $l
    --> Str
  ) {

    my SemiXML::BodyType $btype;

    # When there is something like '$a [ abc $b def ]' $b does not have a
    # body but the 'pre-body' will eat the spaces following it anyway. These
    # spaces belong to $a but will be ignored in that case. the next text $a
    # gets is then 'def ' which should be ' def '. Now to get that right, we
    # first see that this set will only have one member namely 'pre-body'.
    #
    # However, this is also true here '$a [ abc $b [] def ]. Here, the 'prebody'
    # belongs to $b and must be ignored. So '$<body-started>=<?>' is inserted
    # just after the opening '[' of the tag-nody token. This will only be
    # visible in the AST when something of the rule is found and thus will
    # allways force two or more members.

    my Bool $only-pre-body = $body-specs.elems == 1;
    return $body-specs[0].value.Str if $only-pre-body;

    for @$body-specs -> Pair $pair ( :key($k), :value($v)) {

      note "[$element.body-count()] $k".indent($l)
        if $!globals.trace and $!globals.refined-tables<T><parse>;

      given $k {
        when 'body-started' {
          $element.body-count++;
        }

        when 'body-a' {
          my Str $text = $v.Str;

          # Remove all comment
          for $v.caps -> Pair $p ( :key($ba-k), :value($ba-v)) {
            if $ba-k eq 'comment' {
              my $vtxt = $ba-v.Str;
              $text ~~ s/ $vtxt //;
            }
          }

          my SemiXML::Text $t .= new( :text($text), :parent($element));
          $t.body-type = SemiXML::BTBodyA;
          $t.body-number = $element.body-count;

          my Str $v1 = $t.perl;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'body-b' {
          my SemiXML::Text $t .= new( :text($v.Str), :parent($element));
          $t.body-type = SemiXML::BTBodyB;
          $t.body-number = $element.body-count;

          my Str $v1 = $t.perl;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'body-c' {
          my SemiXML::Text $t .= new( :text($v.Str), :parent($element));
          $t.body-type = SemiXML::BTBodyC;
          $t.body-number = $element.body-count;

          my Str $v1 = $t.perl;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'document' {
          self!process-ast( $v, $l+4);
        }
      }
    }

    return '';
  }

  #-----------------------------------------------------------------------------
  # set namespaces on the element
  method !set-namespaces ( SemiXML::Element $element ) {

    # add namespaces xmlns
    my Hash $refIn = $!globals.refined-tables<DN> // {};

    for $refIn.keys -> $ns {
      if $ns eq 'default' {
        $element.attributes<xmlns> = $refIn{$ns};
      }

      else {
        $element.attributes<xmlns:$ns> = $refIn{$ns};
      }
    }
  }

#`{{
  #-----------------------------------------------------------------------------
  # remove leftover elements and attributes from SemiXML namespace
  method !remove-sxml-namespace ( SemiXML::Node $node ) {

    unless $node ~~ SemiXML::Text {

      # remove nodes from the sxml namespace except for the fragment node
      unless $node.name ~~ any(<sxml:fragment sxml:comment sxml:cdata {
        if $node.name ~~ m/^ sxml \: / {
          $node.remove;
          return;
        }

        else {
          # check the node for any sxml namespace attributes and reove them
          for $node.attributes.keys -> $k {
            $node.attributes{$k}:delete if $k ~~ m/^ sxml \: /;
            $node.attributes{$k}:delete if $k ~~ m/^ xmlns \: sxml /;
          }
        }
      }

      self!remove-sxml-namespace($_) for $node.nodes;
    }

    # else is text node of which no attributes gets displayed
  }
}}
}
