use v6;

#-------------------------------------------------------------------------------
use XML;
use SxmlLib::SxmlHelper;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
# Core module with common used methods
class SxmlCore {

  #-----------------------------------------------------------------------------
  method is-method-inline ( Str $method-name --> Bool ) {
    $method-name ~~ any(<date date-time>);
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date year=nn month=nn day=nn []
  method date (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
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
  method date-time (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my Bool $iso = $attrs<iso>:exists ?? ? $attrs<iso>.Int !! True;
    my Bool $utc = $attrs<utc>:exists ?? ? $attrs<utc>.Int !! False;
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
  method comment (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
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
  method cdata (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
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
  method pi (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    $parent.append(
      XML::PI.new(
        :data((
          (( ~$attrs<target> // 'no-target'), $content-body.nodes).join(' ')
        ))
      )
    );
    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.var name=xyz [<data>] generates
  # <sxml:variable name=xyz name="aCommonText">...</sxml:variable>
  # namespace xmlns:sxml="github:MARTIMM" is placed on top level element
  # and removed later when document is ready.
  method var (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my $e = append-element( $parent, 'sxml:variable', %$attrs);
    $e.append($content-body);

    $parent;
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.colors base-color=<color> generates
  # <sxml:variable name=xyz name="aCommonText">...</sxml:variable>
  # namespace xmlns:sxml="github:MARTIMM" is placed on top level element
  # and removed later when document is ready.
  # See also http://scholarship.claremont.edu/cgi/viewcontent.cgi?article=1881&context=cmc_theses
  method colors (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my Str $base-color = ~$attrs<base-color>;

    my $e = append-element( $parent, 'sxml:variable', %(:name<base-color>));
    append-element( $e, :text($base-color));

    $parent;
  }
}
