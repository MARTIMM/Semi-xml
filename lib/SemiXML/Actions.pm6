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

#-------------------------------------------------------------------------------
class Actions {

  has SemiXML::Globals $!globals;

  # the root should only have one element. when there are more, convert
  # the result into a fragment.
  has SemiXML::Element $!root;

  # array of element showing the path to the currently parsed element. therefore
  # an element in the array will always be the parent of the one next to it.
  has Array $!elements;
  has Int $!element-idx;

  has XML::Document $!document;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!globals .= instance;
  }

  #-----------------------------------------------------------------------------
  method TOP ( $match ) {

    # initialize root node and place in the array. this node will never be
    # overwritten.
    $!root .= new(:name<root>);
    $!elements = [$!root];
    $!element-idx = 1;
#note "Idx A: $!element-idx";


note "At the end of parsing";
    self!process-ast($match);


    my XML::Element $root-xml;

    # see how many elements are stored in root
    # return an empty document
    if $!root.nodes.elems == 0 {
note "No elements";
      $root-xml .= new(:name<sxml:EmptyDocument>);
#      $root-xml.setNamespace( 'github.MARTIMM', 'sxml');
#      $!document .= new($ed);
    }

    # normal xml document
    elsif $!root.nodes.elems == 1 {
note "1 element";
      $root-xml .= new(:name($!root.name));
      $!root.nodes[0].xml($root-xml);
#      $!document .= new(
#        $root-xml.nodes[0].defined
#          ?? $root-xml.nodes[0]
#          !! XML::Element.new(:name<sxml:noChildDefined>)
#      );
    }

    elsif $!root.nodes.elems > 1 {
note "More elements";
      $!root.node-type = SemiXML::Fragment;

      $root-xml .= new(:name($!root.name));
      for $!root.nodes -> $node {
        $node.xml($root-xml);
      }

#      $!document .= new($root-xml);
    }

#    my XML::Element $root = $!document.root;
    $root-xml.setNamespace( 'github.MARTIMM', 'sxml');

    unless $!globals.raw {
#      subst-variables($root-xml);
#      remap-content($root-xml);
      remove-sxml($root-xml);

      # remove the namespace declaration
      $root-xml.unset("xmlns:sxml");
    }


    if $!root.nodes.elems == 0 {
      $!document .= new($root-xml);
    }

    elsif $!root.nodes.elems == 1 {
      $!document .= new(
        $root-xml.nodes[0].defined
          ?? $root-xml.nodes[0]
          !! XML::Element.new(:name<sxml:noChildDefined>)
      );
    }

    elsif $!root.nodes.elems > 1 {
      $!document .= new($root-xml);
    }
  }

  #-----------------------------------------------------------------------------
  # get the result document
  method get-document ( --> XML::Document ) {

    #$!document.new(XML::Element.new(:name<root>));
    $!document
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
          my SemiXML::Element $element = self!create-element($v);
          $!elements[$!element-idx] = $element;
          $!elements[$!element-idx - 1].append($element);

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
            my SemiXML::Text $t .= new(:text($pre-body.Str));
            $t.body-type = SemiXML::BodyC;  # dont care really, only spaces
            $t.body-number = $element.body-count;
            $element.append($t);

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
  method !create-element ( $tag --> SemiXML::Element ) {

    my SemiXML::Element $element;

    my Str $symbol = $tag<sym>.Str;
    if $symbol eq '$' {
      $element .= new( :name($tag<tag-name>.Str));
    }

    elsif $symbol eq '$!' {
      $element .= new(
        :module($tag<mod-name>.Str), :method($tag<meth-name>.Str)
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
          my SemiXML::Text $t .= new(:text($v.Str));
          $t.body-type = SemiXML::BodyA;
          $t.body-number = $element.body-count;
          $element.append($t);

          my $v1 = $v;
          $v1 ~~ s:g/ \n /\\n/;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'body-b' {
          my SemiXML::Text $t .= new(:text($v.Str));
          $t.body-type = SemiXML::BodyB;
          $t.body-number = $element.body-count;
          $!elements[$!element-idx - 1].append($t);

          my $v1 = $v;
          $v1 ~~ s:g/ \n /\\n/;
          note "--> append '$v1' to $element.name()".indent($l+4)
            if $!globals.trace and $!globals.refined-tables<T><parse>;
        }

        when 'body-c' {
          my SemiXML::Text $t .= new(:text($v.Str));
          $t.body-type = SemiXML::BodyC;
          $t.body-number = $element.body-count;
          $!elements[$!element-idx - 1].append($t);

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
}
