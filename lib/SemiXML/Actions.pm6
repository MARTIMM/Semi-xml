use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Node;
use SemiXML::Element;
use SemiXML::Text;
use SemiXML::StringList;
use SemiXML::Helper;
use XML;
use XML::XPath;

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

#  has XML::Document $!document;

  has Str $.xml-text;

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
    $!xml-text = '';

#note "\nAt the end of parsing";
    # process the result tree
    self!process-ast($match);

    # execute any method bottom up and generate sxml structures
    $!root.run-method if $!globals.exec;
#note "NTop Tree F=$!globals.frag(), T=$!globals.tree();\n$!root.Str()";

    # Don't generate the xml stuff when only the tree is requested later
    unless $!globals.tree {
      # convert non-method nodes into XML
      #my XML::Element $root-xml .= new(:name($!root.name));
#note "NTop 0: $root-xml";
      #$root-xml.setNamespace( 'https://github.com/MARTIMM/Semi-xml', 'sxml');
      #for $!root.nodes -> $node {
      #  $node.xml($root-xml);
      #}
#note "NTop 1: $root-xml, $!globals.raw()";

#      $!document = from-xml($!xml-text);
#      my XML::Element $root-xml = $!document.root;


      unless $!globals.raw {
#        self!subst-variables($root-xml);
#        self!remap-content($root-xml);

        # remove all tags from the sxml namespace.
        #self!remove-sxml-namespace($!root);
#note "NTop 2d: $root-xml";
      }

      if $!root.nodes.elems == 0 {
note "0 elements";
        $!xml-text = $!root.xml;
      }

      elsif $!root.nodes.elems == 1 {
note "1 element";
        self!set-namespaces($!root.nodes[0]);
        $!xml-text = $!root.nodes[0].xml;
      }

      elsif $!root.nodes.elems > 1 {
note "more than 1 element";
        if $!globals.frag {
          self!set-namespaces($!root.nodes[0]);
          $!xml-text = $!root.xml;
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

note "NTop 3: $!xml-text";
  }

#`{{
  #-----------------------------------------------------------------------------
  # get the result document
  method get-document ( --> XML::Document ) {

    #$!document.new(XML::Element.new(:name<root>));
    #$!document
  }
}}

  #-----------------------------------------------------------------------------
  # get the result sxml
  multi method sxml-tree ( SemiXML::Node:D :$sxml-tree! ) {

    $!root .= new(:name<sxml:fragment>);
    $!root.append($sxml-tree);
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # reverse engineer from xml to sxml tree
  multi method sxml-tree ( XML::Node:D :$xml! ) {

    sub cnvnodes ( XML::Node $parent ) {
      for $parent.nodes -> $node {
        when XML::Element {
        }

        when XML::Text {
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
    my XML::Document $xml = from-xml-file($xml-text);
    self.sxml-tree(:xml($xml.root));
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # get the result sxml
  multi method sxml-tree ( --> SemiXML::Node ) {

    my SemiXML::Node $sxml-tree;
    if $!root.nodes.elems == 0 {
note "0 elements";
      $sxml-tree = $!root;
    }

    elsif $!root.nodes.elems == 1 {
note "1 element";
      $sxml-tree = $!root.nodes[0];
      $sxml-tree.parent(SemiXML::Element.new(:name<X>));
    }

    elsif $!root.nodes.elems > 1 {
note "more than 1 element";
      if $!globals.frag {
        $sxml-tree = $!root;
      }

      else {
        die X::SemiXML.new(
          :message( "Too many nodes on top level. Maximum allowed nodes is one")
        )
      }
    }

note "GST Root: ", $sxml-tree.perl(:simple);
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
            $t.body-type = SemiXML::BodyC;  # dont care really, only spaces
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
          $t.body-type = SemiXML::BodyA;
          $t.body-number = $element.body-count;
          #$element.append($t);

          my $v1 = $text;
          $v1 ~~ s:g/ \n /\\n/;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'body-b' {
          my SemiXML::Text $t .= new( :text($v.Str), :parent($element));
          $t.body-type = SemiXML::BodyB;
          $t.body-number = $element.body-count;
          #$!elements[$!element-idx - 1].append($t);

          my $v1 = $v;
          $v1 ~~ s:g/ \n /\\n/;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'body-c' {
          my SemiXML::Text $t .= new( :text($v.Str), :parent($element));
          $t.body-type = SemiXML::BodyC;
          $t.body-number = $element.body-count;
          #$!elements[$!element-idx - 1].append($t);

          my $v1 = $v;
          $v1 ~~ s:g/ \n /\\n/;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        #when 'topdocument' { proceed; }
        when 'document' {
          self!process-ast( $v, $l+4);
        }
      }
    }

    return '';
  }

  #-----------------------------------------------------------------------------
  # search for variables and substitute them
  method !subst-variables ( XML::Node $parent ) {

    my XML::XPath $x;

    if $parent ~~ XML::Element {
      my XML::Document $xml-document .= new($parent);
      $parent.setNamespace( 'github.MARTIMM', 'sxml');

      # set namespace first
      $x .= new(:document($xml-document));
      $x.set-namespace: 'sxml' => 'github.MARTIMM';
    }

    # else it should be a document
    elsif $parent ~~ XML::Document {
      $x .= new(:document($parent));
      $x.set-namespace: 'sxml' => 'github.MARTIMM';
    }

    else {
      die "Wrong argument type, must be Element or Document";
    }

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

    if $parent ~~ XML::Element {
      # remove the namespace
      $parent.attribs{"xmlns:sxml"}:delete;
    }
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
