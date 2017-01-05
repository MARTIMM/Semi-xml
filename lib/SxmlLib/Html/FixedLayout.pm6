use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML;

#-------------------------------------------------------------------------------
class Html::FixedLayout {
  # $!load-test-example path=<file> []
  #
  # This method will load an example file and will pick the piece of code
  # enclosed in lines of #`{{Example-Start}} and #`{{Example-Stop}}
  #
  # path=<file>
  # start=<stop-mark>   Start is an optional marker to start selecting text.
  #                     Start and stop overides the defaults mentioned above.
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

    if $keep-literal {
      $text ~~ s:g/\</\&lt;/;
      $text ~~ s:g/\>/\&gt;/;
    }

    $fix-indent = Int($fix-indent);
    if $fix-indent > 0 {
      my $rm-indent = ' ' x $fix-indent;
      $text ~~ s:g/^^ $rm-indent//;
    }

    # Make a pre section and place the selected code in it.
    #
    my $pre = XML::Element.new(:name('pre'));
    $parent.append($pre);
    $pre.append(SemiXML::Text.new(:$text));
  }
}
