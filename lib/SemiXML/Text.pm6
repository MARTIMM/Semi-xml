use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Node;
use SemiXML::XMLText;
use XML;

#-------------------------------------------------------------------------------
class Text does SemiXML::Node {

  has Str $.text;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$!text ) {
    $!node-type = SemiXML::NText;
  }

  #-----------------------------------------------------------------------------
  method xml ( XML::Node $parent, Bool :$keep = False ) {
note "Xt: $!node-type, $parent, '$!text'";

    my Str $text = $!text;
    if $keep {

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

            my $l = $line;            # get line
            $l ~~ s/^ $indent//;      # remove the spaces
            $new-text ~= "$l\n";      # add a newline because .lines() removes it
          }

          # except for the last line if there wasn't one in the original
          $new-text ~~ s/ \n+ $// unless $!text ~~ m/ \n $/;
          $text = $new-text;
        }
      }
    }

    else {
      $text ~~ s:g/^^ \s+ //;     # remove leading spaces
      $text ~~ s:g/ \s+ $$//;     # remove trailing spaces
      $text ~~ s:g/ \s\s+ / /;    # replace multiple spaces with one
      $text ~~ s:g/ \n+ //;       # remove return characters
    }

#note "P: $parent";
    $parent.append(SemiXML::XMLText.new(:$text));
  }
}
