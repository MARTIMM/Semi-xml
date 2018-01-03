use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
class Globals {
  has Str $.filename is rw;
  has Hash $.refined-tables is rw;

  my $instance;

  submethod new ( ) { !!! }
  submethod BUILD ( ) { }
  method instance ( --> Globals ) {

    $instance = self.bless unless $instance.defined;

    $instance
  }
}
