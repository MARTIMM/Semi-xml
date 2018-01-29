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
    $!root .= new(:name<sxml:fragment>);
    $!elements = [$!root];
    $!element-idx = 1;

note "\nAt the end of parsing";
    # process the result tree
    self!process-ast($match);

    # execute any method bottom up and generate sxml structures
    $!root.run-method if $!globals.exec;
#note "NTop 0: $root-xml";

    # convert non-method nodes into XML
    my XML::Element $root-xml .= new(:name($!root.name));
    $root-xml.setNamespace( 'https://github.com/MARTIMM/Semi-xml', 'sxml');
    for $!root.nodes -> $node {
      $node.xml($root-xml);
    }
note "NTop 1: $root-xml";

    unless $!globals.raw {
#      self!subst-variables($root-xml);
#      self!remap-content($root-xml);

      # apply all entries from the F Table
      self!apply-f-table($root-xml);


      # remove all tags from the sxml namespace.
      self!remove-sxml($root-xml);

      # remove the namespace declaration, but if there are
      # fragments, we need the namespaces in the document.
      #$root-xml.unset("xmlns:sxml") unless $!globals.frag;
    }
note "NTop 2: $root-xml";

    if $root-xml.nodes.elems == 0 {
note "0 elements";
      $!document .= new($root-xml);
    }

    elsif $root-xml.nodes.elems == 1 {
note "1 element";
      self!set-namespaces($root-xml.nodes[0]);
      $!document .= new($root-xml.nodes[0]);
    }

    elsif $root-xml.nodes.elems > 1 {
note "more than 1 element";
      if $!globals.frag {
        self!set-namespaces($root-xml);
        $!document .= new($root-xml);
      }

      else {
        die X::SemiXML.new(
          :message( "Too many nodes on top level. Maximum allowed nodes is one")
        )
      }
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

  #-----------------------------------------------------------------------------
  # set namespaces on the element
  method !set-namespaces ( XML::Element $element ) {

    # add namespaces xmlns
    my Str $refIn = $!globals.refine[0];
    if $!globals.refined-tables<FN><$refIn>:exists {
      for $!globals.refined-tables<FN><$refIn>.keys -> $ns {
        $element.set(
          $ns eq 'default' ?? 'xmlns' !! "xmlns:$ns",
          $!globals.refined-tables<FN><$refIn>{$ns}
        );
      }
    }
  }

  #-----------------------------------------------------------------------------
  method !apply-f-table ( XML::Node $node ) {
    #clean-text($node);
    self!escape-attr-and-elements($node);
    self!check-inline($node);
  }

  #-----------------------------------------------------------------------------
  method !escape-attr-and-elements ( XML::Node $node ) {

    state $parent-node;

    my SemiXML::Globals $globals .= instance;

    # process body text to escape special chars. we can process this always
    # because parent elements are already accepted to modify the content.
    if $node ~~ any( SemiXML::XMLText, XML::Text) {
      my Str $t = self!cleanup-text( $parent-node, $node);
      my XML::Node $p = $node.parent;
      $p.replace( $node, SemiXML::XMLText.new(:text($t)));
    }

    elsif $node ~~ XML::Element {
#      $comment-preserve = $node.attribs<sxml:content> ~~ any([<B C>]);

      # Check for self closing tag, and if so remove content if any
      if $node.attribs<sxml:close>:exists and $node.attribs<sxml:close> eq '1' {

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
      if $node.attribs<keep>:exists and $node.attribs<sxml:keep> eq '1'  {
        # no escaping must be performed on its contents
        # for these kinds of nodes
        return;
      }

      # no processing either for nodes in the SemiXML namespace
      if $node.name ~~ m/^ 'sxml:' / {
        return;
      }

      # recursivly process through child elements
      $parent-node = $node;
      self!escape-attr-and-elements($_) for $node.nodes;
    }
  }

  #-----------------------------------------------------------------------------
  # Substitute some characters by XML entities, remove the remaining
  # backslashes, remove comments if possible, remove trailing spaces,
  # substitute multiple spaces by one space if possible.
  method !cleanup-text ( XML::Element $parent, XML::Node $node --> Str ) {

    my Str $esc = ~$node;

    # entity must be known in the xml result!
    $esc ~~ s:g/\& <!before '#'? \w+ ';'>/\&amp;/;
    $esc ~~ s:g/\\\s/\&nbsp;/;
    $esc ~~ s:g/ '<' /\&lt;/;
    $esc ~~ s:g/ '>' /\&gt;/;

    # remove comments only if :$comment-preserve = False
note "E0: $esc";
    $esc ~~ s:g/ \s* <!after <[\\]>> '#' \N*: $$// if
      $parent.attribs<sxml:body-type> eq "BodyA";
note "E1: $esc";

    # remove backslashes
    $esc ~~ s:g/'\\'//;

    # remove leading spaces for the minimum number of spaces when the content
    # should be fixed
#note "Space: '$esc'";
    if $parent.attribs<sxml:keep>:exists
       and $parent.attribs<sxml:keep> eq '1' {

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
  method !check-inline ( XML::Element $parent ) {

    my SemiXML::Globals $globals .= instance;

    # get xpath object
    my XML::Document $xml-document .= new($parent);
    $parent.setNamespace( 'https://github.com/MARTIMM/Semi-xml', 'sxml');

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

        elsif $v.nodes[0] ~~ SemiXML::XMLText {
          my SemiXML::XMLText $t = $v.nodes[0];
          my Str $text = $t.text;
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

        elsif $v.nodes[*-1] ~~ SemiXML::XMLText {
          my SemiXML::XMLText $t = $v.nodes[*-1];
          my Str $text = $t.text;
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

        elsif $ps ~~ SemiXML::XMLText {
          my SemiXML::XMLText $t := $ps;
          my Str $text = $t.text;
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

        elsif $ns ~~ SemiXML::XMLText {
          my SemiXML::XMLText $t := $ns;
          my Str $text = $t.text;
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
  method !remove-sxml ( XML::Node $node ) {
    my SemiXML::Globals $globals .= instance;

note "T: $node";
    if $node ~~ XML::Element {
note "\nE: ", $node.name;
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

      self!remove-sxml($_) for $node.nodes;
    }

    elsif $node ~~ XML::Comment {
note "\nC: ", $node.data[*].join('; ');
      self!remove-sxml($_) for $node.data;
    }

    elsif $node ~~ XML::PI {
note "\nP: ", $node.data;
      self!remove-sxml($_) for $node.data;
    }

    if $node ~~ XML::CDATA {
note "\nCD: ", $node.data;
      self!remove-sxml($_) for $node.data;
    }


#`{{
    # get xpath object
    my XML::Document $xml-document .= new($parent);
    $parent.setNamespace( 'https://github.com/MARTIMM/Semi-xml', 'sxml');

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
