use v6.c;
use SemiXML;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Report {

  has $!sxml;

  has $!code-obj;
  has $!test-obj;
  has $!todo-obj;

  has XML::Element $!report-doc;
  has XML::Element $!body;

  has Str $!test-program;

  # Storage of test results. Key is the test code which is like T##/D##. The
  # value is an Array of which the 1st element is the success count and the
  # 2nd the failure count. These are counts so it can be used to do tests in
  # a loop.
  #
  has Hash $!test-results;

  has Hash $!test-metrics;
  has Array $!all-metrics = [];

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $sxml, Hash $attrs ) {

say "\nInit report: ";
for $attrs.kv -> $k, $v { say "$k => $v" };
print "\n";

    $!sxml = $sxml;

    $!test-program = Q:to/EOINIT/;
      use v6.c;
      use Test;

      EOINIT

    $!code-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Code');
    $!test-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Test');
    $!todo-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Todo');

    self!setup-report-doc($attrs);
  }

  #-----------------------------------------------------------------------------
  method run (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    # setup the report document with check mark elements to be replaced later
    # by the results from the prove run
    self!report-template(:$content-body);

    # run tests
    self!run-test($attrs);

    # finish in the results
    self!process-test;

    # display a summary at the bottom of the report
    self!display-summary;

    # Add footer to the end of the report
    my XML::Element $div = append-element( $!body, 'div', {class => 'footer'});
    append-element(
      $div, :text("Generated using SemiXML, SxmlLib::Testing::TestDoc, XML")
    );

    # save report in parent
    $parent.append($!report-doc);

    $parent;
  }

  #-----------------------------------------------------------------------------
  method summary (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    $parent;
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  # Initialize document
  method !setup-report-doc ( Hash $attrs ) {

    # html document
    $!report-doc .= new(:name<html>);

    # make a head and define it
    my XML::Element $head = append-element( $!report-doc, 'head');
    self!setup-head( $head, $attrs);

    # make a body
    $!body = append-element( $!report-doc, 'body');

    # if there is a title attribute, make a h1 title
    if ? $attrs<title> {
      my XML::Element $h1 = append-element(
        $!body, 'h1', { id => '___top', class => 'title'}
      );
      insert-element( $h1, :text($attrs<title>));
    }
  }

  #-----------------------------------------------------------------------------
  # Fill the head element
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
  method !report-template ( XML::Element :$content-body ) {

    my XML::Element $hook;
    my XML::Element $pre;

    my @nodes = $content-body.nodes;
    while @nodes {

      my $node = @nodes.shift;
#say "\nN: ", $node.WHAT;
      if $node ~~ XML::Element
         and $node.name eq '__PARENT_CONTAINER__'
         and $node.nodes[0].name eq 'code' {

#say $node.name;

        # <pre> used to display code in
        $pre = append-element( $!body, 'pre', {:class<test-block-code>});

        # <hook> used to insert test, todo, bug and skip content.
        # $hook is removed later
        #
        $hook = append-element( $!body, 'hook');

        # get code entry number
        my Int $centry = ([~] $node.nodes[0].nodes).Int;
#say "code $centry";

        # get the nodes stored in the code section
        my @code-nodes = $!code-obj.get-code-part($centry).nodes;
        while @code-nodes {

          my $code-node = shift @code-nodes;
#say "Y: ", $code-node.WHAT, ", $code-node";

          # test sections must be translated in code and also inserted just
          # after this <pre> section
          #
          my XML::Element $x;
          $x = $code-node.nodes[0]
             if $code-node ~~ XML::Element
                and $code-node.name eq '__PARENT_CONTAINER__';

          if ? $x {
            if $x.name eq 'test' {

              # get test entry number 
              my Int $tentry = ([~] $code-node[0].nodes).Int;
              my Str $code-text = ~$!test-obj.get-code-text($tentry);
say "test $tentry, $code-text";

              # add test to the <pre> block
              append-element( $pre, :text("$code-text\n"));

              # and to the test program
              $!test-program ~= "$code-text\n";

              # add test text after the <pre> and before the <hook>
              $hook.before($!test-obj.make-table($tentry));
            }

            elsif $x and $x.name eq 'todo' {

              # get test entry number 
              my Int $tentry = ([~] $code-node[0].nodes).Int;
              my Str $code-text = ~$!todo-obj.get-code-text($tentry);
say "todo $tentry, $code-text";

              # Add todo to the <pre> block
              append-element( $pre, :text("$code-text\n"));

              # and to the test program

              # add todo text after the <pre> and before the <hook>
              $hook.before($!todo-obj.make-table($tentry));
              $!test-program ~= "$code-text\n";
            }
          }

          else {
            $pre.append($code-node);
            $!test-program ~= "$code-node\n";
          }
        }
      }

      else {
        $!body.append($node);
      }
    }

    $hook.remove;
  }

  #-----------------------------------------------------------------------------
  # Write test script to file and run prove on it. get the test data and store
  # in $!test-results and $!test-metrics
  #
  method !run-test ( Hash $attrs ) {

    # store the data in a hash
    $!test-results = {};

    # metrics
    $!test-metrics = { T => [0,0], D => [0,0], B => [0,0], S => [0,0]};

    # Finish up the test text and write the text to a file 
    $!test-program ~= "\n\ndone-testing;\n";

say "\n\nCode:\n$!test-program";

    # get a filename for the tests and write
    my $test-file = $attrs<test-file>;
    $test-file //= ($!sxml.get-current-filename ~ '.t');
    $test-file //= ($*TMPDIR.Str ~ '/perl6-test.t');

say "\n\nFile:\n$test-file";

    spurt( $test-file, $!test-program);

    # run the tests using prove and get the result contents through a pipe
    my Proc $p = run 'prove', '--exec', 'perl6', '--verbose', '--merge',
                 '--rules=seq=*', $test-file, :out;

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
        self!set-test-results( $test-code2, $ok, :metric);
      }

      else {
        self!set-test-results( $test-code, $ok);
      }
    }

    # save metric data in a file
    self!save-metrics( $test-file, $attrs);
  }

  #-----------------------------------------------------------------------------
  # Gather metric data and write to metric file.
  method !save-metrics ( Str $test-file, Hash $attrs ) {

    my $c = $*PERL.compiler();

    my $metric-file = $test-file;
    $metric-file ~= "-metric-$*DISTRO.name()-$*DISTRO.version()-$c.name()-$*VM.name()";

    my Str $metric-text = '';

    # gather data from attributes
    $metric-text ~= "Title:{$attrs<title> // '-'}\n";
    $metric-text ~= "Package:{$attrs<package> // '-'}\n";
    $metric-text ~= "Module:{$attrs<module> // '-'}\n";
    $metric-text ~= "Class:{$attrs<class> // '-'}\n";
    $metric-text ~= "Distribution:{$attrs<distribution> // '-'}\n";
    $metric-text ~= "Label:{$attrs<label> // '-'}\n";

    # gather data from compiler and system
    $metric-text ~= "OS-Kernel:$*KERNEL.name():$*KERNEL.version()\n";
    $metric-text ~= "OS-Distro:$*DISTRO.name():$*DISTRO.version():$*DISTRO.release():$*DISTRO.is-win()\n";
    $metric-text ~= "Perl:$*PERL.name():$*PERL.version()\n";
    $metric-text ~= "Compiler:$c.name():$c.version()\n";
    $metric-text ~= "VM:$*VM.name():$*VM.version()\n";

    my Int $total =
      [+] |@($!test-metrics<T>), |@($!test-metrics<B>),
          |@($!test-metrics<D>), |@($!test-metrics<S>);
    $metric-text ~= "Total: $total\n";

    # Gather also in an array
    # total, T-ok, T-nok, T-tota, B-ok, B-nok, ...
    # Start T on [1..3], B on [4..6], D on [7..9], S on [10]
    $!all-metrics = [$total];

    # test metrics
    my Int $ts = [+] @($!test-metrics<T>);
    $!all-metrics.push: $!test-metrics<T>[0], $!test-metrics<T>[1], $ts;
    $metric-text ~= ("T", $!all-metrics[1..3]>>.fmt('%.2f')).join(':') ~ "\n";

    # bug issue metrics
    $ts = [+] @($!test-metrics<B>);
    $!all-metrics.push: $!test-metrics<B>[0], $!test-metrics<B>[1], $ts;
    $metric-text ~= ("B", $!all-metrics[4..6]>>.fmt('%.2f')).join(':') ~ "\n";

    # todo metrics
    $ts = [+] @($!test-metrics<D>);
    $!all-metrics.push: $!test-metrics<D>[0], $!test-metrics<D>[1], $ts;
    $metric-text ~= ("D", $!all-metrics[7..9]>>.fmt('%.2f')).join(':') ~ "\n";

    # skip metrics
    $ts = $!test-metrics<S>[0];
    $!all-metrics.push: $ts;
    $metric-text ~= ("S", $!all-metrics[10].fmt('%.2f')).join(':') ~ "\n";

    spurt( $metric-file, $metric-text);
  }

  #-----------------------------------------------------------------------------
  method !process-test ( ) {

    # search for special elements left and modify these
    my Array $containers = $!report-doc.getElementsByTagName('__CHECK_MARK__');
    for @$containers.reverse -> $node {

      my Str $test-code = $node.attribs<test-code>.Str;

      ( my Int $ok-c, my Int $nok-c) = @($!test-results{$test-code} // [ 0, 0]);
say "TR: $test-code, $ok-c, $nok-c";

      my XML::Element $td;
      if $ok-c {
        $td = before-element( $node, 'td', {class => 'check-mark green'} );
        if $test-code ~~ m/^ 'D' / {
          append-element( $td, :text('&#128459;'));
        }

        elsif $test-code ~~ m/^ 'B' / {
          append-element( $td, :text('&#128459;'));
        }

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
        append-element( $td, :text('&#x1F648;'));
      }

      $node.remove;
    }
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
  method !display-summary ( ) {

    my XML::Element $table = append-element( $!body, 'table');
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
      $tr, $!all-metrics[4], $!all-metrics[5], $!all-metrics[6], 'bug'
    );

    self!simple-pie(
      $tr, $!all-metrics[7], $!all-metrics[8], $!all-metrics[9], 'todo'
    );

    self!summary-pie(
      $tr, $!all-metrics[0],
      ([+] $!all-metrics[1], $!all-metrics[4], $!all-metrics[7]),
      $!all-metrics[2], $!all-metrics[5], $!all-metrics[8],
      $!all-metrics[10]
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

    # colored rectangles with count and text
    self!rectangle( $g, 'test-ok', 0, 0, $all-ok, :text<ok>);
    self!rectangle( $g, 'test-nok', 0, 15, $test-nok, :text<Tests>);
    self!rectangle( $g, 'bug-nok', 0, 30, $bug-nok, :text<Bugs>);
    self!rectangle( $g, 'todo-nok', 0, 45, $todo-nok, :text<Todo>);
    self!rectangle( $g, 'skip', 0, 60, $skip, :text<Skip>);

    # draw a line
    append-element(
      $g, 'path', { class => 'line', d => 'M 0 73 H 40' }
    );

    # total tests ok + not ok
    my XML::Element $t = append-element(
      $g, 'text', { class => 'legend', x => '20', y => '85'}
    );
    append-element( $t, :text("$total"));

    $t = append-element(
      $g, 'text', { class => 'legend', x => '40', y => '85'}
    );
    append-element( $t, :text<Total>);
  }

  #-----------------------------------------------------------------------------
  method !rectangle (
    XML::Element $g, Str $class, Int $x, Int $y, Int $count, Str :$text
  ) {
    append-element(
      $g, 'rect', {
        class => $class,
        x => $x.Str, y => $y.Str,
        width => '15', height => '10'
      }
    );

    my XML::Element $t = append-element(
      $g, 'text', { class => 'legend', x => ($x + 20).Str, y => ($y + 10).Str}
    );
    append-element( $t, :text($count.fmt('%2d')));

    if ? $text {
      $t = append-element(
        $g, 'text', { class => 'legend', x => ($x + 40).Str, y => ($y + 10).Str}
      );
      append-element( $t, :$text);
    }
  }
}



