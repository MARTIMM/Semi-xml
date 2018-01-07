use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Svg:auth<github:MARTIMM>;

use XML;
use XML::XPath;
use SemiXML::Sxml;
use SxmlLib::SxmlHelper;

#-------------------------------------------------------------------------------
class PieChart {

  #-----------------------------------------------------------------------------
  method summary-pie (
#    XML::Element $parent, Int $total, Int $all-ok,
#    Int $test-nok, Int $bug-nok, Int $todo-nok, Int $skip

     XML::Element $parent, Array $parts
  ) {
#`{{
    # Setup a table data field with svg element in it
    my XML::Element $td = append-element( $parent, 'td');
    my XML::Element $svg = append-element(
      $td, 'svg', {
        width => '200', height => '100',
      }
    );
    $svg.setNamespace("http://www.w3.org/2000/svg");

    # Using percentage as circumverence, the radius should be
    my Int $center = 50;
    my Int $radius = 47;
    my Num $circ = 2.0 * pi * $radius;

    # total ok
    # Transform total percentage ok into angle.
    my Num $total-ok = $all-ok * 2.0 * pi / $total;
    my Int $large-angle = $total-ok >= pi ?? 1 !! 0;

    my $new-x = $center + $radius * sin $total-ok;
    my $new-y = $center - $radius * cos $total-ok;
    if $all-ok and $new-x =~= $center and $new-y =~= $center - $radius.Num {
      $new-x -= 1e-2;
      $large-angle = 1;
    }

    append-element(
      $svg, 'path', {
        class => 'test-ok',
        d => [~] "M $center $center l 0 -$radius",
                 "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                 "z"
      }
    );


    # not ok tests
    # Calculate rotation
    my Num $curr-angle = $total-ok;
    my Num $rot = $curr-angle * 360.0 / (2 * pi);
    my XML::Element $g = append-element(
      $svg, 'g', { transform => "rotate( $rot, $center, $center)" }
    );

    my Num $a-nok = $test-nok * 2.0 * pi / $total;
    $large-angle = $a-nok >= pi ?? 1 !! 0;

    $new-x = $center + $radius * sin $a-nok;
    $new-y = $center - $radius * cos $a-nok;
    if $test-nok and $new-x =~= $center and $new-y =~= $center - $radius.Num {
      $new-x -= 1e-2;
      $large-angle = 1;
    }

    append-element(
      $g, 'path', {
        class => 'test-nok',
        d => [~] "M $center $center l 0 -$radius",
                 "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                 "z"
      }
    );


    # not ok bug
    # Calculate rotation
    $curr-angle += $a-nok;
    $rot = $curr-angle * 360.0 / (2 * pi);
    $g = append-element(
      $svg, 'g', { transform => "rotate( $rot, $center, $center)" }
    );

    $a-nok = $bug-nok * 2.0 * pi / $total;
    $large-angle = $a-nok >= pi ?? 1 !! 0;

    $new-x = $center + $radius * sin $a-nok;
    $new-y = $center - $radius * cos $a-nok;
    if $bug-nok and $new-x =~= $center and $new-y =~= $center - $radius.Num {
      $new-x -= 1e-2;
      $large-angle = 1;
    }

    append-element(
      $g, 'path', {
        class => 'bug-nok',
        d => [~] "M $center $center l 0 -$radius",
                 "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                 "z"
      }
    );


    # not ok todo
    # Calculate rotation
    $curr-angle += $a-nok;
    $rot = $curr-angle * 360.0 / (2 * pi);
    $g = append-element(
      $svg, 'g', { transform => "rotate( $rot, $center, $center)" }
    );

    $a-nok = $todo-nok * 2.0 * pi / $total;
    $large-angle = $a-nok >= pi ?? 1 !! 0;

    $new-x = $center + $radius * sin $a-nok;
    $new-y = $center - $radius * cos $a-nok;
    if $todo-nok and $new-x =~= $center and $new-y =~= $center - $radius.Num {
      $new-x -= 1e-2;
      $large-angle = 1;
    }

    append-element(
      $g, 'path', {
        class => 'todo-nok',
        d => [~] "M $center $center l 0 -$radius",
                 "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                 "z"
      }
    );


    # skipped
    # Calculate rotation
    $curr-angle += $a-nok;
    $rot = $curr-angle * 360.0 / (2 * pi);
    $g = append-element(
      $svg, 'g', { transform => "rotate( $rot, $center, $center)" }
    );

    my Num $a-skip = $skip * 2.0 * pi / $total;
    $large-angle = $a-skip >= pi ?? 1 !! 0;

    $new-x = $center + $radius * sin $a-skip;
    $new-y = $center - $radius * cos $a-skip;
    if $skip and $new-x =~= $center and $new-y =~= $center - $radius.Num {
      $new-x -= 1e-2;
      $large-angle = 1;
    }

    append-element(
      $g, 'path', {
        class => 'skip',
        d => [~] "M $center $center l 0 -$radius",
                 "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                 "z"
      }
    );



    # Legend
    my $rect-x = 2 * $center;
    my $rect-y = 5;
    $g = append-element(
      $svg, 'g', { transform => "translate($rect-x,$rect-y)" }
    );

    # ok rectangle
    append-element(
      $g, 'rect', {
        class => 'test-ok',
        x => '0', y => '0',
        width => '15', height => '10'
      }
    );

    # not ok test rectangle
    append-element(
      $g, 'rect', {
        class => 'test-nok',
        x => '0', y => '15',
        width => '15', height => '10'
      }
    );

    # not ok bug rectangle
    append-element(
      $g, 'rect', {
        class => 'bug-nok',
        x => '0', y => '30',
        width => '15', height => '10'
      }
    );

    # not ok todo rectangle
    append-element(
      $g, 'rect', {
        class => 'todo-nok',
        x => '0', y => '45',
        width => '15', height => '10'
      }
    );

    # skip rectangle
    append-element(
      $g, 'rect', {
        class => 'skip',
        x => '0', y => '60',
        width => '15', height => '10'
      }
    );


    # total ok count
    my XML::Element $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '10'}
    );
    append-element( $t, :text("$all-ok"));

    $t = append-element(
      $g, 'text', { class => 'legend', x => '40', y => '10'}
    );
    append-element( $t, :text<Ok>);


    # test not ok count
    $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '25'}
    );
    append-element( $t, :text("$test-nok"));

    $t = append-element(
      $g, 'text', { class => 'legend', x => '40', y => '25'}
    );
    append-element( $t, :text<Tests>);


    # bug not ok count
    $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '40'}
    );
    append-element( $t, :text("$bug-nok"));

    $t = append-element(
      $g, 'text', { class => 'legend', x => '40', y => '40'}
    );
    append-element( $t, :text<Bugs>);


    # todo not ok count
    $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '55'}
    );
    append-element( $t, :text("$todo-nok"));

    $t = append-element(
      $g, 'text', { class => 'legend', x => '40', y => '55'}
    );
    append-element( $t, :text<Todo>);


    # skip count
    $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '70'}
    );
    append-element( $t, :text("$skip"));

    $t = append-element(
      $g, 'text', { class => 'legend', x => '40', y => '70'}
    );
    append-element( $t, :text<Skip>);


    # draw a line
    append-element(
      $g, 'path', { class => 'line', d => 'M 0 73 H 40' }
    );

    # total tests ok + not ok
    $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '85'}
    );
    append-element( $t, :text("$total"));

    $t = append-element(
      $g, 'text', { class => 'legend', x => '40', y => '85'}
    );
    append-element( $t, :text<Total>);
}}
  }
}
