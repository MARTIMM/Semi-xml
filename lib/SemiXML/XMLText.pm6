use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use XML;

#-------------------------------------------------------------------------------
# Must make this class to substitute XML::Text. That class removes all
# spaces at the start and end of the content and removes newlines too
# This is bad for tags like HTML <pre> and friends. With this class, stripping
# can be controlled better.
class XMLText does XML::Node {

  #has Bool $.strip;
  has Str $.text;

  #-----------------------------------------------------------------------------
  method Str ( ) {
    return $!text;
  }

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$!text ) {
  #submethod BUILD ( Bool :$!strip = False, Str :$!text ) {

  #`{{ Following is taken from the XML module but is not working properly
       so the :strip attribute is ignored to keep things in my own hands
    if $!strip {
      $!text ~~ s:g/\s+$$//;   ## Chop out trailing spaces from lines.
      $!text ~~ s:g/^^\s+//;   ## Chop out leading spaces from lines.
      $!text .= chomp;         ## Remove a trailing newline if it exists.
    }
  }}

  }
}
