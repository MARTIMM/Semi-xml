use v6;

#-------------------------------------------------------------------------------
package SemiXML:auth<github:MARTIMM> {

  #-----------------------------------------------------------------------------
  enum NodeType <Fragment Plain NText Method CData PI Comment>;
  enum BodyType <BodyA BodyB BodyC>;

  #-----------------------------------------------------------------------------
  class Globals {
    has Str $.filename is rw;
    has Array $.refine is rw = [<xml xml>];
    has Hash $.refined-tables is rw;
    has Bool $.trace is rw;
    has Bool $.keep is rw;
    has Bool $.raw is rw;
    has Hash $.objects is rw;

    my Globals $instance;

    #---------------------------------------------------------------------------
    submethod new ( ) { !!! }

    #---------------------------------------------------------------------------
    method instance ( --> Globals ) {

      $instance = self.bless unless $instance.defined;

      $instance
    }
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
