use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Node;

#-------------------------------------------------------------------------------
class Text does SemiXML::Node {

  # name counter is used to generate the name for the text node. this
  # must be global to the objects of this class
  my Int $name-counter;

  has Str $.text;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$!text, SemiXML::Node :$parent ) {

    # set node type
    $!node-type = SemiXML::NTText;

    # init rest
    $!globals .= instance;

    # default settings
    $!inline = False;
    $!noconv = False;
    $!keep = False;
    $!close = False;

    # there is no node name for text but here we create a fake name
    # for at most 22 characters starting with 'sxml:TN-' and ending in a
    # hex number. E.g. a node with text "that's me here" and a counter of
    # 200, the name becomes 'sxml:TN-thatsmeher-0C8'
    $name-counter //= 1;
    $!name = $!text;
    $!name ~~ s:g/<punct>//;
    $!name ~~ s:g/\s+//;
    $!name = 'empty' unless ?$!name;
    $!name = [~] 'sxml:TN-', $!name.substr( 0, 10), '-',
                 $name-counter.fmt('%03X');
    $name-counter++;

    # text does not have children but nodes must be initialized
    $!nodes = [];

    # connect to parent. text should always have a parent!
    $parent.append(self) if ?$parent;

    # set sxml attributes
    self!process-attributes;
  }

  #-----------------------------------------------------------------------------
  method xml ( --> Str ) {

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
      $text ~~ s/ \n+ $//;        # remove last return character
      $text ~~ s:g/ \s\s+ / /;    # replace multiple spaces with one
      $text ~~ s:g/^^ \h+ //;     # remove leading spaces
      $text ~~ s:g/ \h+ $$//;     # remove trailing spaces

#      # add one leading space except before a punctuation char
#      $text ~~ s/^ <!before <punct>>/ /;

#`{{
      if $!body-number != $previous-body-number {
        $previous-body-number = $!body-number;
        $text = " $text" if $!body-number > 1;
      }
}}


note "xml: {self.perl}";
      if $!inline {
        my SemiXML::Node $ps = self.previousSibling;
        if $ps.defined {
          if $ps.node-type !~~ SemiXML::NTText {
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
          if $ns.node-type !~~ SemiXML::NTText {
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

    # remove comments only when in BTBodyA. the other content bodies
    # are left alone. only remove when not escaped or after &
#    if $!body-type ~~ SemiXML::BTBodyA {
#      $text ~~ s:g/ \s* <!after <[\\\&]>> '#' \N*: $$//;
#    }

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

#  $!text = $text;
#$parent.append(SemiXML::Text.new(:$text));

note "txt: $!name -> '$text'";
    $text
  }

  #-----------------------------------------------------------------------------
  method Str ( --> Str ) {

    $!text
  }

  #-----------------------------------------------------------------------------
  method perl ( --> Str ) {

    my Str $modifiers = ' (';
    $modifiers ~= $!inline ?? 'i ' !! '¬i '; # inline or block
    $modifiers ~= $!noconv ?? '¬t ' !! 't '; # transform or not
    $modifiers ~= $!keep ?? 'k ' !! '¬k ';   # keep as typed or compress
    $modifiers ~= $!close ?? 's ' !! '¬s ';  # self closing or not

    $modifiers ~= '| ';

    $modifiers ~= 'F' if $!node-type ~~ SemiXML::NTFragment;
    $modifiers ~= 'E' if $!node-type ~~ SemiXML::NTElement;
    $modifiers ~= 'D' if $!node-type ~~ SemiXML::NTCData;
    $modifiers ~= 'P' if $!node-type ~~ SemiXML::NTPI;
    $modifiers ~= 'C' if $!node-type ~~ SemiXML::NTPI;

    $modifiers ~= ')';

    my Str $text = $!text;
    $text ~~ s:g/ \n /\\n/;

    "$!name $modifiers '{$text.substr(0,54)} ...'"
  }
}
