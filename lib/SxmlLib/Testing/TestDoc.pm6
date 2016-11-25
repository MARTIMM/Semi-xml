use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Testing::TestDoc {

  enum TestType <Test Todo Bug Skip>;

  # The test counter is used to generate a description messages with each test
  # like 'T##'. This is also stored in the element _CHECK_MARK_ with a
  # 'test-code' attribute. For todo entries this is D##, B## for bug issue tests
  # S## for skipped test.
  #
  has Int $!test-count = 0;
  has Int $!todo-count = 0;
  has Int $!bug-count = 0;
  has Int $!skip-count = 0;

  # Initialize the test file with a few lines
  has Str $!test-file-content = Q:to/EOINIT/;
    use v6.c;
    use Test;

    EOINIT

  state Str $indent;
  has XML::Element $last-defined-pre;

  # Storage of test results. Key is the test code which is like T##/D##. The
  # value is an Array of which the 1st element is the success count and the
  # 2nd the failure count. These are counts so it can be used to do tests in
  # a loop.
  #
  has Hash $!test-results;

  has Hash $!test-metrics;
  has Array $!all-metrics = [];

  #-----------------------------------------------------------------------------
  method report (
    XML::Element $parent, Hash $attrs, XML::Element :$content-body
  ) {

    # html document
    my XML::Element $top = append-element( $parent, 'html');

    # make a head and define it
    my XML::Element $head = append-element( $top, 'head');
    self!setup-head( $head, $attrs);

    # make a body
    my XML::Element $body = append-element( $top, 'body');

    # Place a hook to work with
    my XML::Element $hook = insert-element( $body, 'hook');

    # if there is a title attribute, make a h1 title
    if ? $attrs<title> {
      my XML::Element $h1 = before-element(
        $hook, 'h1', { id => '___top', class => 'title'}
      );
      insert-element( $h1, :text($attrs<title>));
    }

    # fill body with results
    #
    # Eat from the end of the list and add just after the container element.
    # Somehow they get lost from the array when done otherwise.
    #
    $hook.after($_) for $content-body.nodes.reverse;

    # Finish up the test text and write the text to a file 
    $!test-file-content ~= "\n\ndone-testing;\n";
    my $test-file = $attrs<test-file> // ($*TMPDIR.Str ~ '/perl6-test.t');

    spurt( $test-file, $!test-file-content);

    # Run the tests using prove and get the result contents through a pipe
    my Proc $p = run 'prove', '--exec', 'perl6', '--verbose', '--merge',
                 '--rules=seq=*', $test-file, :out;

    # store the data in a hash
    $!test-results = {};

    # metrics
    $!test-metrics = { T => [0,0], D => [0,0], B => [0,0], S => [0,0]};

    # read lines from pipe from testing command
    my @lines = $p.out.lines;
    loop ( my $l = 0; $l < @lines.elems; $l++) {
      my $line = @lines[$l];

say "R: $line";

      # get the test code if there is one. only for tests and todo(also bugs)
      $line ~~ m/ '-' \s* (<[TDB]> \d+) /;
      my Str $test-code = $0.Str if ? $/;
      my Any $ok = $line ~~ m:s/^ 'ok' /
                   ?? True
                   !! ( $line ~~ m:s/^ 'not' 'ok' /
                        ?? False
                        !! Any
                      );

      # check todo code
      if $line ~~ m/'# TODO' \s* ('D' \d+) $/ {
        my Str $test-code2 = $0.Str if ? $/;
        self!set-test-results( $test-code2, $ok, :!metric);

        self!set-test-results( $test-code, $ok);
      }

      # check bug issue code
      elsif $line ~~ m/'# TODO' \s* ('B' \d+) $/ {
        my Str $test-code2 = $0.Str if ? $/;
        self!set-test-results( $test-code2, $ok, :!metric);

        self!set-test-results( $test-code, $ok);
      }

      # check skip code
      elsif $line ~~ m/'# SKIP' \s* ('S' \d+) $/ {
        my Str $test-code2 = $0.Str if ? $/;
say "TSkip: $test-code, $test-code2";
        self!set-test-results( $test-code2, $ok, :metric);

#        self!set-test-results( $test-code, $ok);
      }

      else {
        self!set-test-results( $test-code, $ok);
      }
    }

    # search for special elements left and modify these
    my $containers = $parent.getElementsByTagName('_CHECK_MARK_');
    for @$containers.reverse -> $node {
      my Str $test-code = $node.attribs<test-code>.Str;

      ( my Int $ok-c, my Int $nok-c) = @($!test-results{$test-code} // [ 0, 0]);

      my XML::Element $td;
      if $ok-c {
        $td = before-element( $node, 'td', {class => 'check-mark green'} );
        if $test-code ~~ m/^ 'D' / {
          append-element( $td, :text('&#128459;'));
        }

        elsif $test-code ~~ m/^ 'B' / {
          append-element( $td, :text('&#128459;'));
        }

#        elsif $test-code ~~ m/^ 'S' / {
#          append-element( $td, :text('&#x1F648;'));
#        }

        else {
          append-element( $td, :text('&#10004;'));
        }

        append-element( $td, :text("$ok-c ")) if $ok-c > 1;
      }

      if $nok-c {
        my Bool $ok-td-exists = $td.defined;
        $td.set( 'class', 'smaller-check-mark green') if $ok-td-exists;

        $td = before-element( $node, 'td', {class => 'check-mark red'});
        $td.set( 'class', 'smaller-check-mark red') if $ok-td-exists;
        if $test-code ~~ m/^ 'D' / {
          append-element( $td, :text('&#128462;'));
        }

        elsif $test-code ~~ m/^ 'B' / {
          append-element( $td, :text('&#128027;'));
        }

#        elsif $test-code ~~ m/^ 'S' / {
#          append-element( $td, :text('&#x1F648;'));
#        }

        else {
          append-element( $td, :text('&#10008;'));
        }

        append-element( $td, :text("$ok-c ")) if $nok-c > 1;
      }

      # Skipped tests
      if not $ok-c and not $nok-c {
        my Bool $ok-td-exists = $td.defined;
        $td.set( 'class', 'smaller-check-mark green') if $ok-td-exists;

        $td = before-element( $node, 'td', {class => 'check-mark red'});
        $td.set( 'class', 'smaller-check-mark red') if $ok-td-exists;
#        if $test-code ~~ m/^ 'S' / {
          append-element( $td, :text('&#x1F648;'));
#        }
      }

      $node.remove;
    }

    # remove hook
    $body.removeChild($hook);

    self!save-metrics( $test-file, $attrs);
    self!display-summary($body);

    # Add footer to the end of the report
    my XML::Element $div = append-element( $body, 'div', {class => 'footer'});

    append-element(
      $div, :text("Generated using SemiXML, SxmlLib::Testing::TestDoc, XML")
    );

    # return parent
    $parent;
  }

  #-----------------------------------------------------------------------------
  method !save-metrics ( Str $test-file, Hash $attrs ) {

    # Gather metric data and write to metric file. Run summary to show.
    my $metric-file = $test-file;
    $metric-file ~~ s/ '.t' $/.t-metric/;

    my $c = $*PERL.compiler();
    $metric-file ~= "-$*DISTRO.name()-$*DISTRO.version()-$c.name()-$*VM.name()";

    my Str $metric-text = '';
    $metric-text ~= "Package:{$attrs<pack> // '-'}\n";
    $metric-text ~= "Module:{$attrs<mod> // '-'}\n";
    $metric-text ~= "Class:{$attrs<class> // '-'}\n";
    $metric-text ~= "Distribution:{$attrs<dist> // '-'}\n";
    $metric-text ~= "Label:{$attrs<label> // '-'}\n";

    $metric-text ~= "OS-Kernel:$*KERNEL.name():$*KERNEL.version()\n";
    $metric-text ~= "OS-Distro:$*DISTRO.name():$*DISTRO.version():$*DISTRO.release():$*DISTRO.is-win()\n";
    $metric-text ~= "Perl:$*PERL.name():$*PERL.version()\n";
    $metric-text ~= "Compiler:$c.name():$c.version()\n";
    $metric-text ~= "VM:$*VM.name():$*VM.version()\n";

#    $metric-text ~= "Package:{$?PACKAGE//'-'}\n";
#    $metric-text ~= "Module:{$?MODULE//'-'}\n";
#    $metric-text ~= "Class:{$?CLASS//'-'}\n";

    my Int $total =
      [+] |@($!test-metrics<T>), |@($!test-metrics<B>),
          |@($!test-metrics<D>), |@($!test-metrics<S>);

    $metric-text ~= "Title:{$attrs<title> // '-'}\n";
    $metric-text ~= "Total: $total\n";

    # Gather also in an array
    # total, T-ok, T-nok, T-total, T%ok, T%nok, %ok, %nok, B-ok, B-nok, ...
    # Start T on [1..7], B on [8..14], D on [15..21], S on [22..28]
    $!all-metrics = [$total];

    my Int $ts = [+] @($!test-metrics<T>);
    $!all-metrics.push: $!test-metrics<T>[0],
                        $!test-metrics<T>[1],
                        $ts,
                        $!test-metrics<T>[0] * 100.0/$ts,
                        $!test-metrics<T>[1] * 100.0/$ts,
                        $!test-metrics<T>[0] * 100.0/$total,
                        $!test-metrics<T>[1] * 100.0/$total;
    $metric-text ~= ("T", $!all-metrics[1..7]>>.fmt('%.2f')).join(':') ~ "\n";

    $ts = [+] @($!test-metrics<B>);
    $!all-metrics.push: $!test-metrics<B>[0],
                        $!test-metrics<B>[1],
                        $ts,
                        $!test-metrics<B>[0] * 100.0/$ts,
                        $!test-metrics<B>[1] * 100.0/$ts,
                        $!test-metrics<B>[0] * 100.0/$total,
                        $!test-metrics<B>[1] * 100.0/$total;
    $metric-text ~= ("B", $!all-metrics[8..14]>>.fmt('%.2f')).join(':') ~ "\n";

    $ts = [+] @($!test-metrics<D>);
    $!all-metrics.push: $!test-metrics<D>[0],
                        $!test-metrics<D>[1],
                        $ts,
                        $!test-metrics<D>[0] * 100.0/$ts,
                        $!test-metrics<D>[1] * 100.0/$ts,
                        $!test-metrics<D>[0] * 100.0/$total,
                        $!test-metrics<D>[1] * 100.0/$total;
    $metric-text ~= ("D", $!all-metrics[15..21]>>.fmt('%.2f')).join(':') ~ "\n";

    $ts = $!test-metrics<S>[0];
    $!all-metrics.push: $ts, $ts * 100.0/$total;
    $metric-text ~= ("S", $!all-metrics[22..23]>>.fmt('%.2f')).join(':') ~ "\n";

    spurt( $metric-file, $metric-text);
  }

  #-----------------------------------------------------------------------------
  method !display-summary ( XML::Element $body ) {

    # See also https://www.smashingmagazine.com/2015/07/designing-simple-pie-charts-with-css/
    #          https://css-tricks.com/how-to-make-charts-with-svg/
    #
    my XML::Element $table = append-element( $body, 'table');
    my XML::Element $tr = append-element( $table, 'tr');
    my XML::Element $th = append-element( $tr, 'th');
    append-element( $th, :text('Normal tests'));
    $th = append-element( $tr, 'th');
    append-element( $th, :text('Bug issues'));
    $th = append-element( $tr, 'th');
    append-element( $th, :text('Todo tests'));
    $th = append-element( $tr, 'th');
    append-element( $th, :text('Summary'));

    $tr = append-element( $table, 'tr');

    self!simple-pie(
      $tr, $!all-metrics[1], $!all-metrics[2], $!all-metrics[3], 'test'
    );

    self!simple-pie(
      $tr, $!all-metrics[8], $!all-metrics[9], $!all-metrics[10], 'bug'
    );

    self!simple-pie(
      $tr, $!all-metrics[15], $!all-metrics[16], $!all-metrics[17], 'todo'
    );



    self!summary-pie(
      $tr, $!all-metrics[0],
      ([+] $!all-metrics[1], $!all-metrics[8], $!all-metrics[15]),
      $!all-metrics[2], $!all-metrics[9], $!all-metrics[16],
      $!all-metrics[22]
    );
  }

  #-----------------------------------------------------------------------------
  method !simple-pie (
    XML::Element $parent, Int $ok, Int $nok, Int $ntests, Str $class
  ) {

    # Setup a table data field with svg element in it
    my XML::Element $td = append-element( $parent, 'td');
    my XML::Element $svg = append-element(
      $td, 'svg', {
        width => '150', height => '100',
#        viewport => '-50 -50 100 100'
      }
    );
    $svg.setNamespace("http://www.w3.org/2000/svg");

    # Using percentage as circumverence, the radius should be
    my Int $center = 50;
    my Int $radius = 47;
    my Num $circ = 2.0 * pi * $radius;

    if $ntests {
      # Transform total percentage ok into angle.
      my Num $total-ok = $ok * 2.0 * pi / $ntests;
      my Int $large-angle = $total-ok >= pi ?? 1 !! 0;

      my Num $new-x = $center + $radius * sin $total-ok;
      my Num $new-y = $center - $radius * cos $total-ok;

      # Recalculate x when $ok == $ntests, a full circle must be drawn
      # but it doesn't whithout a bit tinkering
      if $ok and $new-x =~= $center and $new-y =~= $center - $radius.Num {
        $new-x -= 1e-2;
        $large-angle = 1;
      }

      append-element(
        $svg, 'path', {
          class => $class ~ '-ok',
          d => [~] "M $center $center l 0 -$radius",
                   "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                   "z"
        }
      );

      # Now the not ok part
      my Num $total-nok = $nok * 2.0 * pi / $ntests;
      $large-angle = $total-nok >= pi ?? 1 !! 0;

      $new-x = $center + $radius * sin $total-nok;
      $new-y = $center - $radius * cos $total-nok;
      if $nok and $new-x =~= $center and $new-y =~= $center - $radius.Num {
        $new-x -= 1e-2;
        $large-angle = 1;
      }

      # Calculate rotation
      my Num $rot = $total-ok * 360.0 / (2 * pi);
      my XML::Element $g = append-element(
        $svg, 'g', { transform => "rotate( $rot, $center, $center)" }
      );

      append-element(
        $g, 'path', {
          class => $class ~ '-nok',
          d => [~] "M $center $center l 0 -$radius",
                   "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                   "z"
        }
      );
    }


    # Legend
    my $rect-x = 2 * $center;
    my $rect-y = 5;
    my XML::Element $g = append-element(
      $svg, 'g', { transform => "translate($rect-x,$rect-y)" }
    );

    # ok rectangle
    append-element(
      $g, 'rect', {
        class => $class ~ '-ok',
        x => '0', y => '0',
        width => '15', height => '10'
      }
    );

    # not ok rectangle
    append-element(
      $g, 'rect', {
        class => $class ~ '-nok',
        x => '0', y => '15',
        width => '15', height => '10'
      }
    );


    # ok count
    my XML::Element $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '10'}
    );
    append-element( $t, :text("$ok"));

    # not ok count
    $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '25'}
    );
    append-element( $t, :text("$nok"));

    # draw a line
    append-element(
      $g, 'path', { class => 'line', d => 'M 0 28 H 40' }
    );

    # total tests ok + not ok
    $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '40'}
    );
    append-element( $t, :text("$ntests"));
  }

  #-----------------------------------------------------------------------------
  method !summary-pie (
    XML::Element $parent, Int $total, Int $all-ok,
    Int $test-nok, Int $bug-nok, Int $todo-nok, Int $skip
  ) {

    # Setup a table data field with svg element in it
    my XML::Element $td = append-element( $parent, 'td');
    my XML::Element $svg = append-element(
      $td, 'svg', {
        width => '200', height => '100',
#        viewport => '-50 -50 100 100',
#        transform => 'rotate(-90) translate(-100)'
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

  }

  #-----------------------------------------------------------------------------
  method !set-test-results ( Str $test-code, Any $ok, Bool :$metric = True ) {

    return unless ?$test-code and $ok.defined and $ok ~~ Bool;

    my Str $test-type = $test-code;
    $test-type ~~ s/\d+ $//;

    if $ok {
      $!test-metrics{$test-type}[0]++ if $metric;

      if $!test-results{$test-code} {
        $!test-results{$test-code}[0]++;
      }

      else {
        $!test-results{$test-code} = [ 1, 0];
      }
    }

    else {
      $!test-metrics{$test-type}[1]++ if $metric;

      if $!test-results{$test-code} {
        $!test-results{$test-code}[1]++;
      }

      else {
        $!test-results{$test-code} = [ 0, 1];
      }
    }
  }

  #-----------------------------------------------------------------------------
  method !setup-head ( XML::Element $head, Hash $attrs ) {

    if $attrs<title> {
      my XML::Element $title = append-element( $head, 'title');
      insert-element( $title, :text($attrs<title>));
    }

    my XML::Element $meta = append-element(
      $head, 'meta', {charset => 'UTF-8'}
    );

    append-element(
      $head, 'link',
      { href => "file://%?RESOURCES<TestDoc.css>", rel => 'stylesheet'}
    );
  }

  #-----------------------------------------------------------------------------
  # Save code in pre block with initial indent removed
  method pre (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    my XML::Element $pre = append-element(
      $parent, 'pre',
      {:class<example>}
    );

    my Str $i;
    $i = ($content-body.nodes[0] // '').Str;
    $i ~~ s/^ \n? (\s+) .* $/$0/;

    my XML::Element $hook = append-element( $pre, 'hook');
    for $content-body.nodes.reverse {
      my $l = ~$^a;
      $l ~~ s:g/^^ $i //;
      after-element( $hook, :text("$l\n"));
    }

    $hook.remove;

    if $attrs<viz>:exists and $attrs<viz> eq 'hide' {
      $last-defined-pre.set( 'class', 'hide');
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
#TODO attribute save=$xml
  method code (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    $last-defined-pre = append-element(
      $parent, 'pre',
      {:class<test-block-code>}
    ) if not $last-defined-pre.defined or $attrs<append>:!exists;

    if not ?$indent {
      $indent = ($content-body.nodes[0] // '').Str;
      $indent ~~ s/^ \n? (\s+) .* $/$0/;
    }

    for $content-body.nodes -> $node {
      $!test-file-content ~= "$node\n";
    }

    my XML::Element $hook = append-element( $last-defined-pre, 'hook');
    for $content-body.nodes.reverse {
      my $l = ~$^a;
      $l ~~ s:g/^^ $indent //;
      after-element( $hook, :text("$l\n"));
    }

    $hook.remove;

    if $attrs<viz>:exists and $attrs<viz> eq 'hide' {
      $last-defined-pre.set( 'class', 'hide');
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  method test (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    if $!todo-count {
      self!make-table( $parent, $attrs, :$content-body, :ttype(Todo));
    }

    elsif $!bug-count {
      self!make-table( $parent, $attrs, :$content-body, :ttype(Bug));
    }

    elsif $!skip-count {
      self!make-table( $parent, $attrs, :$content-body, :ttype(Skip));
    }

    else {
      self!make-table( $parent, $attrs, :$content-body, :ttype(Test));
    }

    my Int $test-code = $!test-count++;
say "TC: $test-code, $!todo-count, $!bug-count, $!skip-count";
    my Str $test-code-text = (
       $!todo-count ?? 'D'
                    !! ($!bug-count ?? 'B'
                    !!   ($!skip-count ?? 'S' !! 'T')
                       )
    ) ~ $test-code;

    my Int $nbr-todo;
    my Int $nbr-skip;
    my Str $code-text = ($attrs<line> // '');
    if $code-text ~~ m/^ todo/ {
      if $code-text ~~ m/ (\d+) $/ {
        $nbr-todo = $0.Str.Int;
      }

      else {
        $nbr-todo = 1;
      }

      $code-text = "todo '$test-code-text', $nbr-todo;\n";
      $!test-file-content ~= $code-text;

      append-element( $last-defined-pre, :text("todo '"));
      my XML::Element $b = append-element( $last-defined-pre, 'b');
      append-element( $b, :text($test-code-text));
      append-element( $last-defined-pre, :text("', $nbr-todo;\n"));
    }

    elsif ? $code-text {

      $code-text ~= ",";
      my $line = $code-text;
      $code-text ~= " '$test-code-text';\n";
      $!test-file-content ~= $code-text;

      $line ~= " '";

      append-element( $last-defined-pre, :text($line));
      my XML::Element $b = append-element( $last-defined-pre, 'b');
      append-element( $b, :text($test-code-text));
      append-element( $last-defined-pre, :text("';\n"));
    }

    $!todo-count-- if $!todo-count > 0;
    $!bug-count-- if $!bug-count > 0;
    $!skip-count-- if $!skip-count > 0;
    $parent;
  }

  #-----------------------------------------------------------------------------
  method todo (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    die 'Cannot have todo here when still todo or bug lines are active'
      if $!todo-count or $!bug-count or $!skip-count;

    my Int $test-code = $!test-count++;

    my Int $nbr-todo = $attrs<n>:exists ?? $attrs<n>.Int !! 1;
    $!todo-count = $nbr-todo;
    my Int $test-lines = $attrs<tl>:exists ?? $attrs<tl>.Int !! $nbr-todo;
    $!todo-count = $test-lines;
    self!make-table(
      $parent, $attrs, :$content-body,
      :start, :start-count($nbr-todo), :ttype(Todo)
    );

    my Str $code-text = "todo 'D$test-code', $nbr-todo;\n";
    $!test-file-content ~= $code-text;

    append-element( $last-defined-pre, :text("todo '"));
    my XML::Element $b = append-element( $last-defined-pre, 'b');
    append-element( $b, :text("D$test-code"));
    append-element( $last-defined-pre, :text("', $nbr-todo;\n"));

    $parent;
  }

  #-----------------------------------------------------------------------------
  method bug (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    die 'Cannot have bug here when still todo or bug lines are active'
      if $!todo-count or $!bug-count or $!skip-count;

    my Int $test-code = $!test-count++;

    my Int $nbr-bugs = $attrs<n>:exists ?? $attrs<n>.Int !! 1;
    my Int $test-lines = $attrs<tl>:exists ?? $attrs<tl>.Int !! $nbr-bugs;
    $!bug-count = $test-lines;
say "BC: $!bug-count";
    self!make-table(
      $parent, $attrs, :$content-body,
      :start, :start-count($nbr-bugs), :ttype(Bug)
    );

    my Str $code-text = "todo 'B$test-code', $nbr-bugs;\n";
    $!test-file-content ~= $code-text;

    append-element( $last-defined-pre, :text("todo '"));
    my XML::Element $b = append-element( $last-defined-pre, 'b');
    append-element( $b, :text("B$test-code"));
    append-element( $last-defined-pre, :text("', $nbr-bugs;\n"));

    $parent;
  }

  #-----------------------------------------------------------------------------
  method skip (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    die 'Cannot have skip here when still todo or bug lines are active'
      if $!todo-count or $!bug-count or $!skip-count;

    my Int $test-code = $!test-count++;

    my Int $nbr-skip = $attrs<n>:exists ?? $attrs<n>.Int !! 1;
    $!skip-count = $nbr-skip;
    my Int $test-lines = $attrs<tl>:exists ?? $attrs<tl>.Int !! $nbr-skip;
    $!skip-count = $test-lines;
    self!make-table(
      $parent, $attrs, :$content-body,
      :start, :start-count($nbr-skip), :ttype(Skip)
    );

    my Str $code-text = "skip 'S$test-code', $nbr-skip;\n";
    $!test-file-content ~= $code-text;

    append-element( $last-defined-pre, :text("skip '"));
    my XML::Element $b = append-element( $last-defined-pre, 'b');
    append-element( $b, :text("S$test-code"));
    append-element( $last-defined-pre, :text("', $nbr-skip;\n"));

    $parent;
  }

  #-----------------------------------------------------------------------------
  method !make-table (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body,
    Bool :$start = False,
    Int :$start-count = 1,
    TestType :$ttype
  ) {

    my Str $tcode;
    given $ttype {
      when Test { $tcode = 'T'; }
      when Todo { $tcode = 'D'; }
      when Bug { $tcode = 'B'; }
      when Skip { $tcode = 'S'; }
    }

    my XML::Element $table = append-element(
      $parent, 'table', {class => 'test-table'}
    );

    my XML::Element $tr = append-element( $table, 'tr');
say "append check mark $tcode$!test-count";

    # When starting with test type, only show the comments and start count
    if $start {
      append-element( $tr, 'td', {class => 'check-mark'});
    }

    # Test entries come here when todo counter is not zero
    else {
      append-element( $tr, '_CHECK_MARK_', {test-code => "$tcode$!test-count"});
    }

    my XML::Element $td = append-element( $tr, 'td');
    $td.insert($_) for $content-body.nodes.reverse;
    $td.set( 'class', 'test-comment');

    # Bold test code characters in front of test comment
    my XML::Element $b = insert-element( $td, 'b');
    if $start {
      my Str $t;
      given $ttype {
        
        # No need for special text on tests
        # when Test { }
        
        when Todo {
          $t = 'Next test is a todo test: ' if $start-count == 1;
          $t = "Next $start-count tests are todo tests: " if $start-count > 1;
          insert-element( $b, :text($t));
        }
        
        when Bug {
          $t = 'Next test is a bug issue test: ' if $start-count == 1;
          $t = "Next $start-count tests are bug issue tests: " if $start-count > 1;
          insert-element( $b, :text($t));
        }
        
        when Skip {
          $t = 'Next test is a skip test: ' if $start-count == 1;
          $t = "Next $start-count tests are skipped tests: " if $start-count > 1;
          insert-element( $b, :text($t));
        }
      }
    }

    else {
      # Prefix the comment with the test code
      insert-element( $b, :text("$tcode$!test-count: "));
    }
  }
}

