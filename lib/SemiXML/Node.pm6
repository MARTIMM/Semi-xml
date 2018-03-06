use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;

#-------------------------------------------------------------------------------
role Node {

  has SemiXML::Globals $.globals;

  has Str $.name;
#  has Str $.namespace;

  has Str $!module;
  has Str $!method;

  has Hash $.attributes;

  # references its parent or Nil if on top. when finished it points to
  # the document element at the root
  has SemiXML::Node $.parent;

  # all nodes contained in the bodies.
  has Array $.nodes;

  # body count kept in the node. the body number is the content body where
  # the node was found.
  has Int $.body-count is rw = 0;
  has Int $.body-number is rw = 0;
  has SemiXML::BodyType $.body-type is rw;

  # this nodes type
  has SemiXML::NodeType $.node-type is rw;

  # flags to process the content. element nodes set them and text nodes
  # inherit them. other types like PI, CData etc, do not need it.
  has Bool $.inline is rw;      # inline in FTable
  has Bool $.noconv is rw;      # no-conversion in FTable
  has Bool $.keep is rw;        # space-preserve in FTable
  has Bool $.close is rw;       # self-closing in FTable

  #-----------------------------------------------------------------------------
  multi method parent ( SemiXML::Node:D $!parent ) { self!process-attributes; }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method parent ( Bool:D :$undef!) { $!parent = SemiXML::Node if $undef; }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method parent ( --> SemiXML::Node ) { $!parent }

  #-----------------------------------------------------------------------------
  method undef-nodes ( ) { $!nodes = [] }

  #-----------------------------------------------------------------------------
  method rename ( Str:D $name ) {
    $!name = $name if $name ~~ m/ <alpha><alnum>* (':' <alpha><alnum>*)? /;
  }

  #-----------------------------------------------------------------------------
  # find location of node in nodes array. return Int type if not found.
  method index-of ( SemiXML::Node $find --> Int ) {

    loop ( my Int $i = 0; $i < $!nodes.elems; $i++ ) {
      return $i if $!nodes[$i] === $find;
    }

    Int
  }

  #-----------------------------------------------------------------------------
  # set the parent of this element
  method reparent ( SemiXML::Node $parent --> SemiXML::Node ) {

    self.remove;
    $!parent = $parent;
    self!process-attributes;
    self
  }

  #-----------------------------------------------------------------------------
  # remove a child element from the node list
  method remove ( --> SemiXML::Node ) {

    # remove if it has a parent
    $!parent.remove-child(self) if $!parent;

    self
  }

  #-----------------------------------------------------------------------------
  # remove a node from node list
  method remove-child ( SemiXML::Node $node ) {

    my $pos = self.index-of($node);
    $!nodes.splice( $pos, 1) if $pos.defined;
  }

  #-----------------------------------------------------------------------------
#TODO move into separate module and use with 'handles'
  # append a node to the end of the nodes array if the node is not
  # already in that array.
  multi method append ( SemiXML::Node:D $node! --> SemiXML::Node ) {

    # if node has a parent, remove the node from the parent first
    $node.remove;
note "NApp: node $node.name() removed from $!name";

    # add the node when not found and set the parent in the node
    my $pos = self.index-of($node);
note "NApp: pos={$pos//'-'}";

    unless $pos.defined {
      $!nodes.push($node);
note "NApp Node pushed";
      $node.parent(self);
note "NApp Node parented, {$!parent ?? $!parent.name !! '-'}";
    }

    $node
  }

  #-----------------------------------------------------------------------------
  # insert a node to the start of the nodes array if the node is not
  # already in that array.
  multi method insert ( SemiXML::Node:D $node! --> SemiXML::Node ) {

    $node.remove;
note "NIns: node $node.name() removed from $!name";

    my $pos = self.index-of($node);
note "NIns: pos={$pos//'-'}";

    unless $pos.defined {
      $!nodes.unshift($node);
note "NIns Node unshifted";
      $node.parent(self);
note "NIns Node parented, {$!parent ?? $!parent.name !! '-'}";
    }

    $node
  }

#`{{
  #-----------------------------------------------------------------------------
  multi method before (
    SemiXML::Node $node, SemiXML::Node $new, :$offset=0, *%formatting
    --> SemiXML::Node
  ) {

    my SemiXML::Node $r;

    my Int $pos = self.index-of($node);
    if $pos.defined and $pos >= 0 and ($pos + $offset) <= $!nodes.elems {
      $!nodes.splice( $pos + $offset, 0, $new.reparent(self));
      $new.set-formatting(|%formatting);
      $r = $new;
    }

    $r
  }
}}

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method before (
    SemiXML::Node $node!, :$offset = 0 #, *%formatting
    --> SemiXML::Node
  ) {

#    my SemiXML::Node $r;
    if $!parent.defined {
#      $r = $!parent.before( self, $node, |%formatting);
      my Int $pos = $!parent.index-of(self);
      if $pos.defined and ($pos + $offset) <= $!parent.nodes.elems {
        $!parent.nodes.splice( $pos + $offset, 0, $node.reparent($!parent));
#        $new.set-formatting(|%formatting);
#        $r = $node;
      }

      else {
        die "If there is a parent, pos should be defined!";
      }
    }

    else {
      die "node $!name does not have a parent";
    }

    $node
  }

  #-----------------------------------------------------------------------------
#`{{
  multi method after ( SemiXML::Node $node, SemiXML::Node $new, :$offset=1 ) {

    self.before( $node, $new, :$offset);
  }
}}

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method after ( SemiXML::Node $node!, :$offset = 1 --> SemiXML::Node ) {

#    $!parent.after( self, $node) if $!parent.defined;
#    self.before( self, $node);
note "A0 $!name\.after\($node.name())";



#    my SemiXML::Node $r;
    if $!parent.defined {
note "A1 $!parent.name(): ", $!parent.nodes>>.name.join(' ');
#      $r = $!parent.before( self, $node, |%formatting);
      my Int $pos = $!parent.index-of(self);
note "A2 pos: {$pos//'-'}";
      my Int $loc = $pos + $offset;
      $loc = 0 if $loc < 0;
      $loc = $!parent.nodes.end if $loc > $!parent.nodes.elems;
      if $pos.defined {
        $!nodes.splice( $loc, 0, $node.reparent($!parent));
#        $new.set-formatting(|%formatting);
#        $r = $node;
      }

      else {
        die "If there is a parent, pos should be defined!" unless $pos.defined;
        die "Position + Offset is too low or too high, elems: " ~
            $!parent.nodes.elems ~ ", pos+off = $loc"
              if $loc < 0 or $loc > $!parent.nodes.elems;
      }
    }

    else {
      die "node $!name does not have a parent";
    }

    $node
  }

  #-----------------------------------------------------------------------------
  method previous-sibling ( --> SemiXML::Node ) {

    if $!parent.defined {
      my $pos = $!parent.index-of(self);
      return $!parent.nodes[$pos-1] if $pos > 0;
    }

    return SemiXML::Node;
  }

  #-----------------------------------------------------------------------------
  method next-sibling ( --> SemiXML::Node ) {

    if $!parent.defined {
      my $pos = $.parent.index-of(self);
      return $.parent.nodes[$pos+1] if $pos < $.parent.nodes.end;
    }

    return SemiXML::Node;
  }

  #-----------------------------------------------------------------------------
  method set-formatting ( *%formatting ) {

    $!inline = %formatting<inline> // False;
    $!inline = %formatting<noconv> // False;
    $!inline = %formatting<keep> // False;
    $!inline = %formatting<close> // False;
  }

  #-----------------------------------------------------------------------------
  # copy a few html global attributes; class, data-*, id, style and title.
  method cp-std-attrs ( Hash $attributes ) {

    return unless ?$attributes;

    for $attributes.keys {
      when /^ [ class || data\- \S+ || id || style || title ] $/ {
        $!attributes{$_} = ~$attributes{$_};
      }
    }
  }

  #-----------------------------------------------------------------------------
  # return current attributes
  multi method attributes ( --> Hash ) is rw {
    $!attributes
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # set attributes
  multi method attributes ( Hash:D $!attributes ) {

#note "Attr Node: $!name, ", $!attributes.keys;
    self!process-attributes;
  }

  #-----------------------------------------------------------------------------
  # search xpath like https://www.w3.org/TR/xpath-3/
  multi method search (
    SemiXML::SCode $oper, Str:D $find-node
    --> Array
  ) {

    my Array $search-results = [];

    # find out if search relative to node or from top
    my SemiXML::Node $start-node;

    if $oper ~~ any( SemiXML::SCRoot, SemiXML::SCRootDesc) {
      my SemiXML::Node $parent;
      my $node = self;
      while ($parent = $node.parent).defined {
        $node = $parent;
      }

      $start-node = $node;
    }

    elsif $oper ~~ any( SemiXML::SCChild, SemiXML::SCDesc,
                        SemiXML::SCAttr, SemiXML::SCItem) {
      $start-node = self;
    }

    elsif $oper ~~ any( SemiXML::SCParent, SemiXML::SCParentDesc) {
      $start-node = $!parent // self;
    }

    # define handler
    my $handler = sub ( SemiXML::Node $node ) {
#note "FN: $find-node on $node.name()";
      given $find-node {
        when '*' {
          $search-results.push($node) if $node.node-type ~~ SemiXML::NTElement;
        }

        when 'node()' {
          $search-results.push($node);
        }

        when 'text()' {
          $search-results.push($node) if $node.node-type ~~ SemiXML::NTText;
        }

        when '@*' {
          $search-results.push($node) if $node.attributes.elems;
        }

        when /^ '@' $<key>=(\w+) $/ {
          my Str $k = ~($/.hash<key>);
          $search-results.push($node) if $node.attributes{$k}:exists;
        }

        when /^ '@' $<key>=(\w+) '=' $<value>=(.*) $/ {
          my Str $k = ~($/.hash<key>);
          my Str $v = ~($/.hash<value>);
          $search-results.push($node)
            if $node.attributes{$k}:exists and $node.attributes{$k} ~~ $v;
        }

        default {
          $search-results.push($node) if $node.name eq $find-node;
        }
      }

#note "SR: ", $search-results;
    }

    # check if we have to go down recursively
    my Bool $recurse = $oper ~~ any(
       SemiXML::SCDesc, SemiXML::SCRootDesc, SemiXML::SCParentDesc
    );

    # check current node for attributes
    my Bool $attribute = $oper ~~ SemiXML::SCAttr;

    # loop through the nodes and select what is needed
    self.process-nodes( $start-node, $handler, :$recurse, :$attribute);

    $search-results
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method search ( Array:D $search --> Array ) {

    my Array $search-results = [self];

    for @$search -> SemiXML::SCode $oper, Str $find-node {
      my Array $srs = $search-results;
      $search-results = [];
      for @$srs -> $sr {
        $search-results.push($_) for @($sr.search( $oper, $find-node));
      }
    }

    $search-results
  }

  #-----------------------------------------------------------------------------
  method process-nodes (
    SemiXML::Node $node, Code $handler, Bool :$recurse = False,
    Bool :$attribute = False
  ) {

    # test attributes on node
    if $attribute {
      $handler($node);
    }

    # test nodes on children
    else {
      # breath first
      for $node.nodes -> $n {
        $handler($n);
      }

      if $recurse {
        for $node.nodes -> $n {
          self.process-nodes( $n, $handler, :$recurse);
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  # search for variables and substitute them
  method subst-variables ( ) {

    # look for variable declarations start search from root
    #for $x.find( '//sxml:var-decl', :to-list) -> $vdecl {
    for @(self.search([ SemiXML::SCRootDesc, 'sxml:var-decl'])) -> $vdecl {
note "VD: ", $vdecl.attributes<name>;

      # get the name of the variable
      my Str $var-name = ~$vdecl.attributes<name>;

      # see if it is a global declaration
#      my Bool $var-global = $vdecl.attributes<global>:exists;

      # now look for the variable to substitute but only starting from this node
      my Array $var-use;
#      if $var-global {
#        $var-use = self.search( [
#            SemiXML::SCRootDesc, 'sxml:var-ref',
#            SemiXML::SCAttr, '@name=' ~ $var-name
#          ]
#        );
#      }

#      else {
        $var-use = self.search( [
            SemiXML::SCParentDesc, 'sxml:var-ref',
            SemiXML::SCAttr, '@name=' ~ $var-name
          ]
        );
#      }

      for @$var-use -> $vuse {
note "VU: ", $vuse.attributes<name>;
        for $vdecl.nodes.reverse -> $vdn {
          $vuse.after($vdn.clone-node($vuse.parent));
        }

        # the variable declaration is substituted remove the element
        $vuse.remove;
      }

      # all variables are substituted, remove declaration too, unless it is
      # defined global. Other parts may have been untouched.
      #$vdecl.remove unless $var-global;
    }
  }

  #----[ private stuff ]--------------------------------------------------------
  # process the text processing control parameters and set sxml attributes
  # of the node. This is done for elements as well as text nodes.
  method !process-attributes ( ) {

#note "PA 0: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
    # a normal element might have entries in the FTable configuration.
    # when entries aren't found, results are False.
    my Hash $ftable = $!globals.refined-tables<F> // {};
    $!inline = $!name ~~ any(|@($ftable<inline> // []));
    $!noconv = $!name ~~ any(|@($ftable<no-conversion> // []));
    $!keep = $!name ~~ any(|@($ftable<space-preserve> // []));
    $!close = $!name ~~ any(|@($ftable<self-closing> // []));

#note "PA 1: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
    # then inherit the data from the parent. root doesn't have a parent as well
    # as method generated nodes
    if ?$!parent {
      $!inline = ($!parent.inline or $!inline);
      $!noconv = ($!parent.noconv or $!noconv);
      $!keep = ($!parent.keep or $!keep);
      $!close = ($!parent.close or $!close);
    }

#note "PA 2: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
    # keep can be overruled by a global keep when True
    $!keep or= $!globals.keep;

#note "PA 3: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
    # then the sxml attributes on the node overrule all
    for $!attributes.keys -> $key {
      given $key {
        when /^ sxml ':' inline / {
          $!inline = $!attributes{$key}.Int.Bool;
        }

        when /^ sxml ':' noconv / {
          $!noconv = $!attributes{$key}.Int.Bool;
        }

        when /^ sxml ':' keep / {
          $!keep = $!attributes{$key}.Int.Bool;
        }

        when /^ sxml ':' close / {
          $!close = $!attributes{$key}.Int.Bool;
        }
      }
    }
#note "PA 4: $!name, i=$!inline, n=$!noconv, k=$!keep, c=$!close ";
  }
}
