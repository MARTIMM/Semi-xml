use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::StringList;

class SxmlElement {

  has SemiXML::Globals $!globals;

  has SemiXML::SxmlElement $!parent;
  has Array[SemiXML::SxmlElement] $!children;

  has Str $!name;
  has Str $!namespace;

  has Str $!module;
  has Str $!method;

  has SemiXML::ElementType $!type;

  has Hash $!attributes;

  #-----------------------------------------------------------------------------
  multi submethod BUILD (
    Str:D :$!name!, Hash :$!attributes, SemiXML::SxmlElement :$!parent
  ) {
    $!globals .= instance;
    $!type = SemiXML::Element;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD (
    Str:D :$!module!, Str:D :$!method!, Hash :$!attributes,
    SemiXML::SxmlElement :$!parent
  ) {
    $!globals .= instance;
    $!type = SemiXML::Method;
  }

  #-----------------------------------------------------------------------------
  method perl ( --> Str ) {

    my Str $e - '';
    if $!type ~~ SemiXML::Element {
      $e = '$' ~ $!name ~ ' ...';
    }

    else {
      $e = '$!' ~ $!module ~ '.' ~ $!method ~ ' ...';
    }

    $e
  }
}
