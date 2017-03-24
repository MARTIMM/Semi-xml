use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
# StringList is used to have attributes with a split brain like IntStr and the
# like. Normally they are used as a string value but with methods they can
# have a value as a list.
#
class StringList {

  has Str $.string;
  has List $.list;
  has Bool $.use-as-list;

  submethod BUILD (
    Str:D :$!string, Str :$delimiter = ' ', Bool :$!use-as-list = False
  ) {
    $!list = $!string.split($delimiter);
  }
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
multi sub prefix:<~>( SemiXML::StringList $x --> Str ) is export {
  $x.string;
}

#-------------------------------------------------------------------------------
multi sub prefix:<`>( SemiXML::StringList $x --> List ) is export {
  $x.list;
}
