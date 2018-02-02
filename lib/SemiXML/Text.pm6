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
  submethod BUILD ( Str :$!text, SemiXML::Node :$parent ) {

    # set node type
    $!node-type = SemiXML::NText;

    # init rest
    $!globals .= instance;
    $!inline = False;
    $!noconv = False;
    $!keep = False;
    $!close = False;

    # create a fake name for text
    $!name = $!text;
    $!name ~~ s:g/<punct>//;
    $!name ~~ s:g/\s+//;
    $!name = 'empty' unless ?$!name;
    $!name = 'sxml:TN' ~ $!name.substr( 0, 40);

    # connect to parent, root doesn't have a parent
    $parent.append(self) if ?$parent;

    # set sxml attributes. these are removed later
    self!process-attributes;
  }

  #-----------------------------------------------------------------------------
  method xml ( XML::Node $parent ) {

    my Str $t;
#$t = $!text;
#$t ~~ s:g/\n/\\n/;
#note "$!node-type, $!body-number, i=$!inline, n=$!noconv, k=$!keep, c=$!close  $!parent.name(), '$t'";

    state $previous-body-number = -1;

    my Str $text = $!text;
    if $!keep {

      # do this only when there are any newlines
      $text ~~ m:g/ (\n) /;
      if $/.elems > 1 {
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
#TODO make an indent of at least 1 character?

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

      $text ~~ s:g/ \n+ / /;      # remove return characters
      $text ~~ s/ \n+ $//;
      $text ~~ s:g/ \s\s+ / /;    # replace multiple spaces with one
      $text ~~ s:g/^^ \h+ //;     # remove leading spaces
      $text ~~ s:g/ \h+ $$//;     # remove trailing spaces

#`{{
      if $!body-number != $previous-body-number {
        $previous-body-number = $!body-number;
        $text = " $text" if $!body-number > 1;
      }
}}

      if $!inline {

        my SemiXML::Node $ps = self.previousSibling;
        if $ps.defined {
          if $ps.node-type !~~ SemiXML::NText {
            $t = ~$ps;
            $text = ' ' ~ $text if $t ~~ m/ \S $/;
          }

          else {
            my Str $t = $ps.text;
            $text = ' ' ~ $text if $t ~~ m/ \S $/;
          }
        }

        my SemiXML::Node $ns = self.nextSibling;
        if $ns.defined {
          if $ns.node-type !~~ SemiXML::NText {
            $t = ~$ns;

            # if the next sibling is inline or keep, spaces will be inserted
            # or kept as it was. In the case both are off, the spaces are
            # removed and only a space is needed when no punctuation exists.
            if !$ns.inline and !$ns.keep {
              $text ~= ' ' if $t !~~ m/^ \s* <punct> /
            }
          }

          else {
            $t = $ns.text;
              if !$ns.inline and !$ns.keep {
              $text ~= ' ' if $t !~~ m/^ \s* <punct> /
            }
          }
        }
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


#$t = $text;
#$t ~~ s:g/\n/\\n/;
#note "$!node-type ==>> '$t'";

    $!text = $text;
    $parent.append(SemiXML::XMLText.new(:$text));
  }
}
