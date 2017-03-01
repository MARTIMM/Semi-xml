use v6.c;

#-------------------------------------------------------------------------------
use XML;
use SemiXML::Sxml;

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
                --> XML::Node
              ) {

    $parent.append(XML::Text.new(:text(' ')));

    my Date $today = Date.today;

    my Int $year = ($attrs<year> // $today.year.Str).Int;
    my Int $month = ($attrs<month> // $today.month.Str).Int;
    my Int $day = ($attrs<day> // $today.day.Str).Int;

    append-element( $parent, :text(Date.new( $year, $month, $day).Str));

    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date-time timezone=tz iso=n []
  method date-time ( XML::Element $parent,
                     Hash $attrs,
                     XML::Node :$content-body   # Ignored
                     --> XML::Node
                   ) {

    my Bool $iso = $attrs<iso>:exists ?? ?$attrs<iso>.Int !! True;
    my Bool $utc = $attrs<utc>:exists ?? ?$attrs<utc>.Int !! False;
    my Int $tz = $attrs<timezone>:exists ?? $attrs<timezone>.Int !! 0;

    my DateTime $date-time;

    if $tz {
      $date-time = DateTime.now(:timezone($tz));
    }

    else {
      $date-time = DateTime.now;
    }

    $date-time .= utc if ?$utc;
    my Str $dtstr = $date-time.Str;

    if !$iso {
      $dtstr ~~ s/'T'/ /;
      $dtstr ~~ s/'+'/ +/;
      $dtstr ~~  s/\.\d+//;
    }

    append-element( $parent, :text($dtstr));
    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.comment []
  method comment ( XML::Element $parent,
                   Hash $attrs,
                   XML::Node :$content-body
                   --> XML::Node
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
                 --> XML::Node
               ) {

    # Textify all body content
    my Str $cdata-content = [~] $content-body.nodes;

    # Remove container tags from the text
    $cdata-content ~~ s:g/ '<' '/'? '__PARENT_CONTAINER__>' //;

    $parent.append(XML::CDATA.new(:data($cdata-content)));
    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.pi []
  method pi ( XML::Element $parent,
              Hash $attrs,
              XML::Node :$content-body
              --> XML::Node
            ) {

    $parent.append(
      XML::PI.new(:data(( $attrs<target>, $content-body.nodes).join(' ')))
    );
    $parent;
  }
}
