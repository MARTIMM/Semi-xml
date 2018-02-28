use v6;

#-------------------------------------------------------------------------------
package SemiXML:auth<github:MARTIMM> {

  #-----------------------------------------------------------------------------
  enum NodeType <NTFragment NTElement NTText NTXml NTVDecl NTVRef
                 NTMethod NTCData NTPI NTComment
                >;
  enum BodyType <BTBodyA BTBodyB BTBodyC>;

  # Root      /x        only at start
  # RootDesc  //x       idem
  # Desc      x//y      relative to current node
  # Child     x         idem
  # Parent    ..
  # Current   .
  # Attr      x[@a=v]   use pair
  #           x/@a      use str
  # Item      x[1]      first item of list of nodes
  enum SCode <
    SCRoot SCChild SCDesc SCRootDesc SCParent SCParentDesc
    SCAttr
    SCItem
  >;

  #-----------------------------------------------------------------------------
  class Globals {

    has Str $.filename is rw;
    has Array $!per-call-options;
    my Globals $instance;

    #---------------------------------------------------------------------------
    submethod new ( ) { !!! }

    #---------------------------------------------------------------------------
    submethod BUILD ( ) {

      # initialize and set defaults. this entry will never be popped
      $!per-call-options = [
        hash(
          :!trace, :!keep, :!raw, :exec, :!frag, :!tree,
          :objects({}), :refine([<xml xml>]), :refined-tables({}),
        ),
      ];
    }

    #---------------------------------------------------------------------------
    method instance ( --> Globals ) {

      $instance = self.bless unless $instance.defined;

      $instance
    }

    #---------------------------------------------------------------------------
    method set-options ( Hash:D $options ) {

      my @keys = <trace keep raw exec frag refine refined-tables objects>;
      my Hash $h = hash(@keys Z=> $options{@keys});

      $!per-call-options.push: $h;
    }

    #---------------------------------------------------------------------------
    # pop options but keep first always on stack
    method pop-options ( ) {
      $!per-call-options.pop if $!per-call-options.elems > 1;
    }

    #---------------------------------------------------------------------------
    # getters
    method trace ( --> Bool ) { $!per-call-options[*-1]<trace>; }
    method keep ( --> Bool ) { $!per-call-options[*-1]<keep>; }
    method raw ( --> Bool ) { $!per-call-options[*-1]<raw>; }
    method exec ( --> Bool ) { $!per-call-options[*-1]<exec>; }
    method frag ( --> Bool ) { $!per-call-options[*-1]<frag>; }
    method tree ( --> Bool ) { $!per-call-options[*-1]<tree>; }

    #method filename ( --> Str ) { $!per-call-options[*-1]<filename>; }
    method refine ( --> Array ) { $!per-call-options[*-1]<refine>; }
    method refined-tables ( --> Hash ) {
      $!per-call-options[*-1]<refined-tables>;
    }
    method objects ( --> Hash ) { $!per-call-options[*-1]<objects>; }
  }
}

#-------------------------------------------------------------------------------
class X::SemiXML is Exception {

  has Str $.message;

  #-----------------------------------------------------------------------------
  submethod BUILD ( :$!message ) { }

  #-----------------------------------------------------------------------------
  # prevent a stackdump, see 'Uncaught Exceptions' at
  # https://docs.perl6.org/language/exceptions#Catching_exceptions
  multi method gist(X::SemiXML:D:) { $.message }
}
