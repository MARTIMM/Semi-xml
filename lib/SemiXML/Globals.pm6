use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

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
