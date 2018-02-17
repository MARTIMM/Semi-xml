use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Element;

#-------------------------------------------------------------------------------
# Core module with common used methods
class SxmlCore {

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date year=nn month=nn day=nn []
  method date ( SemiXML::Element $method ) {

    my Date $today = Date.today;

    my Int $year = ($method.attributes<year> // $today.year.Str).Int;
    my Int $month = ($method.attributes<month> // $today.month.Str).Int;
    my Int $day = ($method.attributes<day> // $today.day.Str).Int;

    $method.before(
      SemiXML::Text.new(:text(Date.new( $year, $month, $day).Str))
    );
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.date-time timezone=tz iso=n []
  method date-time ( SemiXML::Element $method ) {

    my Bool $iso = ($method.attributes<iso> // 1).Int.Bool;
    my Bool $utc = ($method.attributes<utc> // 0).Int.Bool;
    my Int $tz = ($method.attributes<timezone> // 0).Int;

    my DateTime $date-time;

    if $tz {
      $date-time = DateTime.now(:timezone($tz));
    }

    else {
      $date-time = DateTime.now;
    }

    $date-time .= utc if ?$utc;
    my Str $dtstr = $date-time.Str;

    unless $iso {
      $dtstr ~~ s/'T'/ /;
      $dtstr ~~ s/'+'/ +/;
      $dtstr ~~  s/\.\d+//;
    }

    $method.before(SemiXML::Text.new( :text($dtstr)));
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.var-decl name=xyz [<data>] generates
  # <sxml:var-decl name=xyz>...</sxml:var-decl>
  # namespace xmlns:sxml="github:MARTIMM" is placed on top level element
  # and removed later when document is ready.
  method var-decl ( SemiXML::Element $method ) {

    my $var = SemiXML::Element.new(
      :name<sxml:var-decl>, :attributes($method.attributes)
    );

    for $method.nodes.reverse -> $node {
      $var.insert($node);
    }

    # If global attribute is 1, place the declaration at the top as
    # its first element
    if $method.attributes<global> // False {
      my Array $r = $method.search([ SemiXML::SCRoot, '*']);
      $r[0].insert($var);
    }

    else {
      $method.before($var);
    }
  }

  #-----------------------------------------------------------------------------
  # $!SxmlCore.drop []
  # Remove all that is enclosed by not processing them
  method drop ( SemiXML::Element $parent ) {  }
}
