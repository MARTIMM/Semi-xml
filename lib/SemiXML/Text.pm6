use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Node;
use SemiXML::XMLText;
use SemiXML::Helper;
use XML;

#-------------------------------------------------------------------------------
class Text does SemiXML::Node {

  has Str $.text;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$!text ) {

    # set node type
    $!node-type = SemiXML::NText;

    # init rest
    $!globals .= instance;

    # create a fake name for text
    $!name = $!text;
    $!name ~~ s:g/<punct>//;
    $!name ~~ s:g/\s+//;
    $!name = 'empty' unless ?$!name;
    $!name = 'sxml:TN' ~ $!name.substr( 0, 40);

    # set sxml attributes. these are removed later
    self!process-attributes;
  }

  #-----------------------------------------------------------------------------
  method xml ( XML::Node $parent ) {
my Str $t = $!text;
$t ~~ s:g/\n/\\n/;
note "$!node-type, $!body-number, $!parent.name(), '$t'";

    state $previous-body-number = -1;

    my Str $text = $!text;
    if $!keep {

      # do this only when there are any newlines
      if $text ~~ m/ \n / {
        # remove leading spaces for the minimum number of spaces when the
        # content should be kept as it is typed in. this is done to prevent
        # that the indent in the text is too much it is compared to the element
        # owning this part.
        my Int $min-indent = 1_000_000_000;
        for $text.lines -> $line {

          # get the number of chars for the indent.
          $line ~~ m/^ $<indent>=(\s*) /;
          my Int $c = $/<indent>.Str.chars;

          # adjust minimum only when there is something non-space on the line
          # to prevent that an empty line will minimize to the minimum possible
          $min-indent = $c if $line ~~ m/\S/ and $c < $min-indent;
        }

        # create a spaces string which is 'substracted' from each line
        if $min-indent > 0 {
          my Str $indent = ' ' x $min-indent;
          my $new-text = '';
          for $text.lines -> $line {

            my $l = $line;        # get line
            $l ~~ s/^ $indent//;  # remove the spaces
            $new-text ~= "$l\n";  # add a newline because .lines() removes it
          }

          # except for the last line if there wasn't one in the original
          $new-text ~~ s/ \n+ $// unless $!text ~~ m/ \n $/;
          $text = $new-text;
        }
      }
    }

    else {

      $text ~~ s:g/^^ \h+ //;     # remove leading spaces
      $text ~~ s:g/ \h+ $$//;     # remove trailing spaces
      $text ~~ s:g/ \s\s+ / /;    # replace multiple spaces with one
      $text ~~ s:g/ \n+ //;       # remove return characters
      $text ~~ s/ \n+ $//;
      $text ~~ s:g/ \n+ / /;

      if $!body-number != $previous-body-number {
        $previous-body-number = $!body-number;
        $text = " $text" if $!body-number != 1;
      }
    }

    # modifications
    unless $!noconv {

      # replace & for &amp; except for cases which are already entities
      # like '&#123;' or '&copy;'
      $text ~~ s:g/\& <!before '#'? \w+ ';'>/\&amp;/;

      $text ~~ s:g/\\\s/\&nbsp;/;
      $text ~~ s:g/ '<' /\&lt;/;
      $text ~~ s:g/ '>' /\&gt;/;
    }

    # remove comments only when in BodyA. the other content bodies
    # are left alone. only remove when not escaped or after &
    if $!body-type ~~ SemiXML::BodyA {
      $text ~~ s:g/ \s* <!after <[\\\&]>> '#' \N*: $$//;
    }

    # remove escape characters
    $text ~~ s/\\//;
#`{{
    # Remove rest of the backslashes unless followed by hex numbers prefixed
    # by an 'x'
    #
    if $esc ~~ m/ '\\x' <xdigit>+ / {
      my $set-utf8 = sub ( $m1, $m2) {
        return Blob.new( :16($m1.Str), :16($m2.Str)).decode;
      };

      $esc ~~ s:g/ '\\x' (<xdigit>**2) (<xdigit>**2) /{&$set-utf8( $0, $1)}/;
    }
}}



    $parent.append(SemiXML::XMLText.new(:$text));
  }
}
