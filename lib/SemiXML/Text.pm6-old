use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use XML;

#-------------------------------------------------------------------------------
# Must make this class to substitute on XML::Text. That class removes all
# spaces at the start and end of the content and removes newlines too
# This is bad for tags like HTML <pre> and friends. With this class stripping
# can be controlled better.
#
class Text does XML::Node {

  has Bool $.strip;
  has Str $.txt;

  method Str ( ) {
    return $!txt;
  }

  submethod BUILD ( Bool :$strip = False, Str :$text ) {

    $!strip = $strip;
    $!txt = $text;

    if $strip {
      $!txt ~~ s:g/\s+$$//;   ## Chop out trailing spaces from lines.
      $!txt ~~ s:g/^^\s+//;   ## Chop out leading spaces from lines.
      $!txt .= chomp;         ## Remove a trailing newline if it exists.
    }
  }
}
