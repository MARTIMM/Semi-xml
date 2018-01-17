use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use XML;

#-------------------------------------------------------------------------------
class Text {

  has Str $.text;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$!text ) { }

  #-----------------------------------------------------------------------------
  method xml ( Bool :$keep = False --> XML::Text ) {

    my Str $text = $!text;
    if $keep {
      # remove leading spaces for the minimum number of spaces when the
      # content should be kept as it is typed in. this is done to prevent
      # that the indent in the text is too much it is compared to the element
      # owning this part.
      my Int $min-indent = 1_000_000_000;
      for $text.lines -> $line {

        # get the number of chars for the indent.
        $line ~~ m/^ $<indent>=(\s*) /;
        my Int $c = $/<indent>.Str.chars;

        # adjust minimum only when there is something non-spacical on the line
        # to prevent that an empty line will minimize to the minimum possible
        $min-indent = $c if $line ~~ m/\S/ and $c < $min-indent;
      }

      # create a spaces string which is 'substracted' from each line
      my Str $indent = ' ' x $min-indent;
      my $new-text = '';
      for $text.lines -> $line {

        my $l = $line;            # get line
        $l ~~ s/^ $indent//;      # remove the spaces
        $new-text ~= "$l\n";      # add a newline because .lines() removes it
      }

      $text = $new-text;
    }

    else {
      $text ~~ s:g/^^ \s+ //;     # remove leading spaces
      $text ~~ s:g/ \s+ $$//;     # remove trailing spaces
      $text ~~ s:g/ \s\s+ / /;    # replace multiple spaces with one
      $text ~~ s:g/ \n+ / /;      # remove return characters
    }

    XML::Text.new(:$text)
}
