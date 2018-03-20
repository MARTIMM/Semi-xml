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
}

#-------------------------------------------------------------------------------
class X::SemiXML::Parse is Exception {

  has Str $.message;

  #-----------------------------------------------------------------------------
  submethod BUILD ( :$!message ) { }

  #-----------------------------------------------------------------------------
  # prevent a stackdump, see 'Uncaught Exceptions' at
  # https://docs.perl6.org/language/exceptions#Catching_exceptions
  multi method gist(X::SemiXML::Parse:D:) { $.message }
}

#-------------------------------------------------------------------------------
class X::SemiXML::Core is Exception {

  has Str $.message;

  #-----------------------------------------------------------------------------
  submethod BUILD ( :$!message ) { }

  #-----------------------------------------------------------------------------
  # prevent a stackdump, see 'Uncaught Exceptions' at
  # https://docs.perl6.org/language/exceptions#Catching_exceptions
  multi method gist(X::SemiXML::Core:D:) { $.message }
}
