use v6.c;

#-------------------------------------------------------------------------------
use XML;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
# Core module with common used methods
class SxmlCore {

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date year=nn month=nn day=nn []
  method date ( XML::Element $parent,
                Hash $attrs,
                XML::Node :$content-body   # Ignored
              ) {

#      $parent.append(XML::Text.new(:text(Date.today().Str)));
    $parent.append(XML::Text.new(:text(' ')));

    my Int $year = +$attrs<year> if ? $attrs<year>;
    my Int $month = +$attrs<month> if ? $attrs<month>;
    my Int $day = +$attrs<day> if ? $attrs<day>;

    if ? $year and ? $month and ? $day {
      $parent.append(
        XML::Text.new(
          :text(Date.new( $year, $month, $day).Str)
        )
      );
    }

    elsif ? $year {
      if ? $month and ? $day {
        $parent.append(
          XML::Text.new(
            :text(Date.new( :$year, :$month, :$day).Str)
          )
        );
      }

      elsif ? $month {
        $parent.append(
          XML::Text.new(
            :text(Date.new( :$year, :$month).Str)
          )
        );
      }

      elsif ? $day {
        $parent.append(
          XML::Text.new(
            :text(Date.new( :$year, :$day).Str)
          )
        );
      }

      else {
        $parent.append(
          XML::Text.new(
            :text(Date.new(:$year).Str)
          )
        );
      }
    }

    else {
      $parent.append(
        XML::Text.new(
          :text(Date.today().Str)
        )
      );
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date-time timezone=tz iso=n []
  method date-time ( XML::Element $parent,
                     Hash $attrs,
                     XML::Node :$content-body   # Ignored
                   ) {

#      my $date-time = DateTime.now().Str;
    my $date-time;

    if $attrs<timezone> {
      $date-time = DateTime.now(:timezone($attrs<timezone>.Int)).Str;
    }

    else {
      $date-time = DateTime.now().Str;
    }

    $date-time ~~ s/'T'/ / unless $attrs<iso>:exists;
    $date-time ~~ s/'+'/ +/ unless $attrs<iso>:exists;
#      my $txt-e = XML::Text.new(:text($date-time));
#      $parent.append($txt-e);
    $parent.append(XML::Text.new(:text($date-time)));
    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.comment []
  method comment ( XML::Element $parent,
                   Hash $attrs,
                   XML::Node :$content-body
                 ) {

    # Textify all body content
    my Str $comment-content = [~] $content-body.nodes;

    # Remove textitified container tags from the text
    $comment-content ~~ s:g/ '<' '/'? '__PARENT_CONTAINER__>' //;

    $parent.append(XML::Comment.new(:data($comment-content)));
    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.cdata []
  method cdata ( XML::Element $parent,
                 Hash $attrs,
                 XML::Node :$content-body
               ) {

    # Textify all body content
    my Str $cdata-content = [~] $content-body.nodes;

    # Remove textitified container tags from the text
    $cdata-content ~~ s:g/ '<' '/'? '__PARENT_CONTAINER__>' //;

    $parent.append(XML::CDATA.new(:data($cdata-content)));
    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.pi []
  method pi ( XML::Element $parent,
              Hash $attrs,
              XML::Node :$content-body
            ) {
    $parent.append(XML::PI.new(:data([~] $content-body.nodes)));
    $parent;
  }
}
