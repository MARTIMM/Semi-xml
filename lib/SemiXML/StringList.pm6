use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
# StringList is used to have attributes with a split brain like IntStr and the
# like. Normally they are used as a string value but with methods they can
# have a list as its value.
#
class StringList does Callable {

  has Str $.string;
  has List $.list;
  has Bool $.use-as-list;
  has $!delimiter;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    Str :$!string = '',
    :$!delimiter where $_ ~~ any(Str|Regex) = ' ',
    Bool :$!use-as-list = False
  ) {
    $!list = $!string.split($!delimiter).List;
  }

  #-----------------------------------------------------------------------------
  # Combination of BUILD() and value()
  submethod CALL-ME (
    Str :$string,
    :$delimiter where $_ ~~ any(Any|Str|Regex),
    Bool :$use-as-list

    --> Any
  ) {

    die 'Not an object' unless self.defined;

    $!delimiter = $delimiter // $!delimiter;
    $!string = $string // $!string;
    $!use-as-list = $use-as-list // $!use-as-list;
    $!list = $!string.split($!delimiter).List;

    $!use-as-list ?? $!list !! $!string;
  }

  #-----------------------------------------------------------------------------
  method value ( --> Any ) {
    $!use-as-list ?? $!list !! $!string;
  }

  #-----------------------------------------------------------------------------
  method Str ( --> Str ) {
    self.string;
  }

  #-----------------------------------------------------------------------------
  method Int ( --> Int ) {
    $!list[0].Int;
  }

  #-----------------------------------------------------------------------------
  method Numeric ( --> Numeric ) {
    + $!list[0];
  }

  #-----------------------------------------------------------------------------
  method List ( --> List ) {
    self.list;
  }

  #-----------------------------------------------------------------------------
  method Bool ( --> Bool ) {
    ? self.string;
  }
}
