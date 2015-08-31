use v6;

#BEGIN {
#  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
#}

use Semi-xml;
use XML;

package SxmlLib:auth<https://github.com/MARTIMM> {

  class Docbook5::FixedLayout {
    # $!load-test-example path=<file> []
    #
    # This method will load an example file and will pick the piece of code
    # enclosed in lines of #`{{Example-Start}} and #`{{Example-Stop}}
    #
    # path=<file>
    # start=<stop-mark>   Start is an optional marker to start selecting text.
    #                     Strat and stop overides the defaults mentioned above.
    # stop=<stop-mark>    Stop is an optional marker to stop selecting text
    # keep-literal=<0/1>  Substitute < > characters with &lt; and &gr;
    # fix-indent=<n>      Remove some space in front of every line.
    #
    method load-test-example ( XML::Element $parent, Hash $attrs is copy ) {
      my Str $path = $attrs<path>:delete // '';
      my Str $ltype = $attrs<ltype>:delete // '';
      my Str $start = $attrs<start>:delete // '#`{{Example-Start}}';
      my Str $stop = $attrs<stop>:delete // '#`{{Example-Stop}}';
      my Bool $keep-literal = $attrs<keep-literal>:delete ?? True !! False;
      my $fix-indent = $attrs<fix-indent>:delete // '0';
      my $callout-prefix = $attrs<callout-prefix>:delete // 'c.';
      my $callout-rows = $attrs<callout-rows>:delete // '';
      my $callout-col = $attrs<callout-col>:delete // '80';

      my $text;
      if $path.IO ~~ :r {
        $text = slurp($path);

        # Find all sections between code markers
        #
        $text ~~ m:g:i/$start(.*?)<?before $stop>/;
        my $c;
        if $/.elems {
          for @$/ -> $m is copy {
            # I am not shure why it is included but we remove it here
            #
            $m ~~ s:i/\n? $start \n?//;

            # Put all code sections together and separate them with '...'
            #
            $c ~= ?$c ?? "...\n$m\n" !! "$m";
          }

          $text = $c;
        }
      }

      else {
        $text = 'empty file or not found';
      }

      $fix-indent = Int($fix-indent);
      if $fix-indent > 0 {
        my $rm-indent = ' ' x $fix-indent;
        $text ~~ s:g/^^ $rm-indent//;
      }

      # Create the container
      #
      my $pl = XML::Element.new(:name('programlisting'));
      $parent.append($pl);

      # When callouts must be placed in the text, the text must be added in
      # pieces with the callout tags in between on the proper places.
      #
      if ?$callout-rows {
        $callout-col = Int($callout-col);
#say "CR 0: $callout-rows, $callout-col";

        my $text-start-line = 0;
        my $callout-count = 1;
        my @cl-rows = $callout-rows.split(/<[\s,]>+/);
        if @cl-rows.elems {
          my @lines = $text.split(/\n/);
          for @cl-rows -> $row is copy {
            $row = Int($row);
#say "CR 1: $row";

            # If row is within limits of the text then add a callout
            #
            if 0 <= $row < @lines.elems {
#say "CR 2: ", @lines[$row].chars;
              # If line is too short add spaces
              #
              if @lines[$row].chars < $callout-col {
                @lines[$row] ~= ' ' x $callout-col - @lines[$row].chars;
              }
              
              # If line is too long truncate the line
              #.
              elsif @lines[$row].chars > $callout-col {
                @lines[$row] = @lines[$row].substr( 0, $callout-col);
              }

              $text = @lines[$text-start-line..$row].join("\n");
              if $keep-literal {
                $text ~~ s:g/\</\&lt;/;
                $text ~~ s:g/\>/\&gt;/;
              }
              
              $pl.append(Semi-xml::Text.new(:$text));
              my $co = XML::Element.new(
                :name('co'),
                :attribs(
                  hash('xml:id' => $callout-prefix ~ $callout-count.fmt('%02d'))
                )
              );

              $pl.append($co);
              $pl.append(Semi-xml::Text.new(:text("\n")));
              $text-start-line = $row + 1;
#say "CR 3: ", $pl.Str;
              $callout-count++;
            }
          }

          # Append remaining text to the container
          #
          if $text-start-line < @lines.elems {
            $text = @lines[$text-start-line ..^ @lines.elems].join("\n");
            if $keep-literal {
              $text ~~ s:g/\</\&lt;/;
              $text ~~ s:g/\>/\&gt;/;
            }
            $pl.append(Semi-xml::Text.new(:$text));
          }
        }
      }
      
      else {
        # Place the selected code in the container
        #
        $pl.append(Semi-xml::Text.new(:$text));
      }
    }
  }
}
