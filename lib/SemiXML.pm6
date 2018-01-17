use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
enum NodeType <Fragment Element Method CData PI Comment>;

#-------------------------------------------------------------------------------
class Globals {
  has Str $.filename is rw;
  has Array $.refine is rw = [<xml xml>];
  has Hash $.refined-tables is rw;
  has Bool $.trace is rw;
  has Bool $.keep is rw;
  has Bool $.raw is rw;
  has Hash $.objects is rw;

  my Globals $instance;

  #-----------------------------------------------------------------------------
  submethod new ( ) { !!! }

  #-----------------------------------------------------------------------------
  method instance ( --> Globals ) {

    $instance = self.bless unless $instance.defined;

    $instance
  }
}
