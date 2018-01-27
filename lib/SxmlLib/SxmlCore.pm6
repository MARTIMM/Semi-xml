use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::StringList;
use SemiXML::Helper;
use SemiXML::SxmlHelper;
use XML;

#-------------------------------------------------------------------------------
# Core module with common used methods
class SxmlCore {

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date year=nn month=nn day=nn []
  method date (
    SemiXML::Element $parent, Hash $attrs, Array[SemiXML::Node] :$content-body
#    --> XML::Node
  ) {

    $parent.append(SemiXML::Text.new(:text(' ')));

    my Date $today = Date.today;

    my Int $year = ($attrs<year> // $today.year.Str).Int;
    my Int $month = ($attrs<month> // $today.month.Str).Int;
    my Int $day = ($attrs<day> // $today.day.Str).Int;

    append-element( $parent, :text(Date.new( $year, $month, $day).Str));

#    $parent
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date year=nn month=nn day=nn []
  method xml-date (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    $parent.append(XML::Text.new(:text(' ')));

    my Date $today = Date.today;

    my Int $year = ($attrs<year> // $today.year.Str).Int;
    my Int $month = ($attrs<month> // $today.month.Str).Int;
    my Int $day = ($attrs<day> // $today.day.Str).Int;

    append-xml-element( $parent, :text(Date.new( $year, $month, $day).Str));

    $parent
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
    $parent
  }

#`{{
  #-----------------------------------------------------------------------------
  # $!SxmlCore.comment []
  method comment (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    # cleanup parent-containers
    drop-parent-container($content-body);
    $parent.append(XML::Comment.new(:data($content-body.nodes)));
    $parent
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.cdata []
  method cdata (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    # cleanup parent-containers
    drop-parent-container($content-body);
    $parent.append(XML::CDATA.new(:data($content-body.nodes)));
    $parent
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.pi []
  method pi (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    drop-parent-container($content-body);
    $parent.append(
      XML::PI.new(
        :data(
          XML::Text.new(
            :text(($attrs<target> // 'no-target').Str)
          ), |$content-body.nodes
        )
      )
    );

    $parent
  }
}}

  #-----------------------------------------------------------------------------
  # $!SxmlCore.var-decl name=xyz [<data>] generates
  # <sxml:var-decl name=xyz name="aCommonText">...</sxml:var-decl>
  # namespace xmlns:sxml="github:MARTIMM" is placed on top level element
  # and removed later when document is ready.
  method var-decl (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my $e = append-element( $parent, 'sxml:var-decl', %$attrs);
    $e.append($content-body);

    $parent
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.drop []
  # Remove all that is enclosed
  method drop (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {
    $parent
  }
}
