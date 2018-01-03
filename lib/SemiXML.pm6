use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
class Globals {
  has Str $.filename is rw;
  has Hash $.refined-tables is rw;
  has Bool $.trace is rw;
  has Bool $.keep is rw;

  my Globals $instance;

  #-----------------------------------------------------------------------------
  submethod new ( ) { !!! }

  #-----------------------------------------------------------------------------
  method instance ( --> Globals ) {

    $instance = self.bless unless $instance.defined;

    $instance
  }
}
