use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Element;
use SemiXML::Text;

#-------------------------------------------------------------------------------
class Docbook5::FixedLayout {

  #-----------------------------------------------------------------------------
  # $!load-test-example path=<file> []
  #
  # This method will load an example file and will pick the piece of code
  # enclosed in lines of #`{{Example-Start}} and #`{{Example-Stop}}
  #
  # path=<file>
  # start=<start-mark>  Start is an optional marker to start selecting text.
  #                     Start and stop overides the defaults mentioned above.
  # stop=<stop-mark>    Stop is an optional marker to stop selecting text
  # keep-literal=<0/1>  Substitute < > characters with &lt; and &gr;
  # fix-indent=<n>      Remove some space in front of every line.
  #
  method load-test-example ( SemiXML::Element $m ) {
    my Str $path = ~($m.attributes<path> // '');
    my Str $ltype = ~($m.attributes<ltype> // '');
    my Str $start = ~($m.attributes<start> // '#`{{Example-Start}}');
    my Str $stop = ~($m.attributes<stop> // '#`{{Example-Stop}}');
    my Bool $keep-literal =
       ($m.attributes<keep-literal>:exists and ?$m.attributes<keep-literal>) ?? True !! False;
    my $fix-indent = ~($m.attributes<fix-indent> // '0');
    my $callout-prefix = ~($m.attributes<callout-prefix> // 'c.');
    my $callout-rows = ~($m.attributes<callout-rows> // '');
    my $callout-col = ~($m.attributes<callout-col> // '80');

    my $text;
    if $path.IO ~~ :r {
      $text = slurp($path);

      my $c;

      # Find all sections between code markers
      $text ~~ m:g:i/$start(.*?)<?before $stop>/;
      if $/.elems {
        for @$/ -> $m is copy {

          # I am not shure why it is included but we remove it here
          $m ~~ s:i/\n? $start \n?//;

          # Put all code sections together and separate them with '...'
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
    my $pl = SemiXML::Element.new(:name<programlisting>);
    $m.before($pl);

    # When callouts must be placed in the text, the text must be added in
    # pieces with the callout tags in between on the proper places.
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
          if 0 <= $row < @lines.elems {
#say "CR 2: ", @lines[$row].chars;
            # If line is too short add spaces
            #
            if @lines[$row].chars < $callout-col {
              @lines[$row] ~= ' ' x $callout-col - @lines[$row].chars;
            }

            # If line is too long truncate the line
            elsif @lines[$row].chars > $callout-col {
              @lines[$row] = @lines[$row].substr( 0, $callout-col);
            }

            $text = @lines[$text-start-line..$row].join("\n");
            if $keep-literal {
              $text ~~ s:g/\</\&lt;/;
              $text ~~ s:g/\>/\&gt;/;
            }

            $pl.append(SemiXML::Text.new(:$text));
            my $co = SemiXML::Element.new(
              :name('co'),
              :attribs(
                hash('xml:id' => $callout-prefix ~ $callout-count.fmt('%02d'))
              )
            );

            $pl.append($co);
            $pl.append(SemiXML::Text.new(:text("\n")));
            $text-start-line = $row + 1;
#say "CR 3: ", $pl.Str;
            $callout-count++;
          }
        }

        # Append remaining text to the container
        if $text-start-line < @lines.elems {
          $text = @lines[$text-start-line ..^ @lines.elems].join("\n");
          if $keep-literal {
            $text ~~ s:g/\</\&lt;/;
            $text ~~ s:g/\>/\&gt;/;
          }
          $pl.append(SemiXML::Text.new(:$text));
        }
      }
    }

    else {
      # Place the selected code in the container
      $pl.append(SemiXML::Text.new(:$text));
    }
  }
}
