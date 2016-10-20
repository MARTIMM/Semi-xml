use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Testing::TestDoc {
  has Hash $.symbols = {};


  #-----------------------------------------------------------------------------
  method test (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body   # Ignored
  ) {
  
    $parent;
  }

  #-----------------------------------------------------------------------------
  method doc (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body   # Ignored
  ) {
  
    $parent;
  }

  #-----------------------------------------------------------------------------
  method prepair (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body   # Ignored
  ) {
  
    $parent;
  }

  #-----------------------------------------------------------------------------
  method is (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body   # Ignored
  ) {
  
    $parent;
  }

  #-----------------------------------------------------------------------------
  method ok (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body   # Ignored
  ) {
  
    $parent;
  }
}

