use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Testing::TestDoc {

  # The test counter is used to generate a description messages with each test
  # like 'T##'. This is also stored in the element _CHECK_MARK_ with a
  # 'test-code' attribute. For todo entries this is D##, B## for bug issue tests
  # S## for skipped test.
  #
  has Int $!test-count = 0;
  has Int $!todo-count = 0;
  has Int $!bug-count = 0;

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

    # Run the test using prove and get the result contents through a pipe
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

      # get the test code if there is one
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

      elsif $line ~~ m/'# TODO' \s* ('B' \d+) $/ {
        my Str $test-code2 = $0.Str if ? $/;
        self!set-test-results( $test-code2, $ok, :!metric);

        self!set-test-results( $test-code, $ok);
      }

      else {
        self!set-test-results( $test-code, $ok);
      }
    }

    # run tests and store in result file
    # read result file and map to a Hash
    #
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

        append-element( $td, :text("$nok-c")) if $nok-c > 1;
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
    my Str $metric-text = '';

    $metric-text ~= "Title:{$attrs<title> // '-'}\n";
    $metric-text ~= "Class:{$attrs<class> // '-'}\n";
    $metric-text ~= "Label:{$attrs<label> // '-'}\n";

    $metric-text ~= "Kernel:$*KERNEL.name():$*KERNEL.version()\n";
    $metric-text ~= "Distro:$*DISTRO.name():$*DISTRO.version():$*DISTRO.release():$*DISTRO.is-win()\n";
    $metric-text ~= "VM:$*VM.name():$*VM.version()\n";

    my Int $total =
      [+] |@($!test-metrics<T>), |@($!test-metrics<B>),
          |@($!test-metrics<D>), |@($!test-metrics<S>);

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

    $ts = [+] @($!test-metrics<S>);
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
    append-element( $th, :text('Skipped tests'));

    $tr = append-element( $table, 'tr');

    self!simple-pie( $tr, $!all-metrics[3], $!all-metrics[4], 'test');
    self!simple-pie( $tr, $!all-metrics[10], $!all-metrics[11], 'bug');
    self!simple-pie( $tr, $!all-metrics[17], $!all-metrics[18], 'todo');
    self!simple-pie( $tr, $!all-metrics[22], $!all-metrics[23], 'skip');
  }

  #-----------------------------------------------------------------------------
  method !simple-pie (
    XML::Element $parent, $ntests, Rat $metric, Str $class
  ) {

    my XML::Element $td = append-element( $parent, 'td');
    my XML::Element $svg = append-element(
      $td, 'svg', { width => '100', height => '100'}
    );
    $svg.setNamespace("http://www.w3.org/2000/svg");

    # Using percentage as circumverence, the radius should be
    my Int $center = 50;
    my Int $radius = 47;
    my Num $circ = 2.0 * pi * $radius;

    if $ntests {
      # Transform total percentage ok into angle.
      my Num $total-ok = $metric * 2.0 * pi / 100.0;
      my Int $large-angle = $total-ok >= pi ?? 1 !! 0;
say "MT: $metric, $total-ok";

      my $new-x = $center + $radius * sin $total-ok;
      my $new-y = $center - $radius * cos $total-ok;
say "XY: $new-x, $new-y";

      my XML::Element $path = append-element(
        $svg, 'path', {
          class => $class,
          d => [~] "M $center $center l 0 -$radius",
                   "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                   "z"
#          d => [~] "M $radius $radius", "L $radius 0",
#                   "A $radius $radius 0 $large-angle 1 $new-x $new-y",
#                   "z"
        }
      );
    }
  }

  #-----------------------------------------------------------------------------
  method !summary-pie (
    XML::Element $parent, $ntests, Rat $metric, Str $class
  ) {

    my XML::Element $td = append-element( $parent, 'td');
    my XML::Element $svg = append-element(
      $td, 'svg', {
        width => '100', height => '100',
#        viewport => '-50 -50 100 100',
#        transform => 'rotate(-90) translate(-100)'
      }
    );
    $svg.setNamespace("http://www.w3.org/2000/svg");

    # Using percentage as circumverence, the radius should be
    my Int $center = 50;
    my Int $radius = 47;
    my Num $circ = 2.0 * pi * $radius;
#say "RC: $radius, $circ";

#`{{
    my XML::Element $g = append-element(
      $svg, 'g',
#       { transform => "rotate(10)",}
#       { transform => "translate($center,$center)",}
    );
}}
    if $ntests {
      # Transform total percentage ok into angle.
      my Num $total-ok = $metric * 2.0 * pi / 100.0;
      my Int $large-angle = $total-ok >= pi ?? 1 !! 0;
say "MT: $metric, $total-ok";

      my $new-x = $center + $radius * sin $total-ok;
      my $new-y = $center - $radius * cos $total-ok;
say "XY: $new-x, $new-y";

      my XML::Element $path = append-element(
        $svg, 'path', {
          class => 'ok-path',
          d => [~] "M $center $center l 0 -$radius",
                   "A $radius $radius 0 $large-angle 1 $new-x $new-y",
                   "z"
#          d => [~] "M $radius $radius", "L $radius 0",
#                   "A $radius $radius 0 $large-angle 1 $new-x $new-y",
#                   "z"
        }
      );
    }

#`{{
    if $ntests {

      # Tests(T) total percentage ok
      my Num $total-ok = $metric * $circ / 100.0;

  say "RCT: $radius, $circ, $total-ok";

      my XML::Element $circle = append-element(
        $svg, 'circle', {
          class => 'test',
          r => "$radius", cx => "$radius", cy => "$radius",
          stroke-dasharray => "$total-ok $circ"
        }
      );
    }

    else {

      my XML::Element $circle = append-element(
        $svg, 'circle', {
          class => 'empty',
          r => "$radius", cx => "$radius", cy => "$radius",
#          stroke-dasharray => "0 $circ"
        }
      );
    }
}}
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
#TODO attribute todo=1 to prefix with a todo test, generate a different checkmarker
  method test (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    if $!todo-count {
      self!todo-table( $parent, $attrs, :$content-body);
    }

    elsif $!bug-count {
      self!bug-table( $parent, $attrs, :$content-body);
    }

    else {
      self!test-table( $parent, $attrs, :$content-body);
    }

    my Int $test-code = $!test-count++;
    my Str $test-code-text = (
       $!todo-count ?? 'D' !! ($!bug-count ?? 'B' !! 'T')
    ) ~ $test-code;

    my Int $nbr-todo;
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
    $parent;
  }

  #-----------------------------------------------------------------------------
  method !test-table ( 
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    my XML::Element $table = append-element(
      $parent, 'table', {class => 'test-table'}
    );

    my XML::Element $tr = append-element( $table, 'tr');
    append-element( $tr, '_CHECK_MARK_', {test-code => "T$!test-count"});
    my XML::Element $td = append-element( $tr, 'td');
    $td.insert($_) for $content-body.nodes.reverse;
    $td.set( 'class', 'test-comment');

    # Prefix the comment with the test code
    my XML::Element $b = insert-element( $td, 'b');
    insert-element( $b, :text("T$!test-count: "));
  }

  #-----------------------------------------------------------------------------
  method todo (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    die 'Cannot have todo here when still todo or bug lines are active'
      if $!todo-count or $!bug-count;

    my Int $test-code = $!test-count++;

    my Int $nbr-todo = $attrs<n>:exists ?? $attrs<n>.Int !! 1;
    $!todo-count = $nbr-todo;
    my Int $test-lines = $attrs<tl>:exists ?? $attrs<tl>.Int !! $nbr-todo;
    $!todo-count = $test-lines;
    self!todo-table(
      $parent, $attrs, :$content-body,
      :todo, :todo-count($nbr-todo)
    );

    my Str $code-text = "todo 'D$test-code', $nbr-todo;\n";
    $!test-file-content ~= $code-text;
#`{{
    append-element( $last-defined-pre, :text("todo '"));
    my XML::Element $b = append-element( $last-defined-pre, 'b');
    append-element( $b, :text("D$test-code"));
    append-element( $last-defined-pre, :text("', $nbr-todo;\n"));
}}
    $parent;
  }

  #-----------------------------------------------------------------------------
  method !todo-table (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body,
    Bool :$todo = False,
    Int :$todo-count = 1
  ) {

    my XML::Element $table = append-element(
      $parent, 'table', {class => 'test-table'}
    );

    my XML::Element $tr = append-element( $table, 'tr');

    # When handling todo, only show the comments and count of todo
    if $todo {
      append-element( $tr, 'td', {class => 'check-mark'});
    }

    # Test entries come here when todo counter is not zero
    else {
      append-element( $tr, '_CHECK_MARK_', {test-code => "D$!test-count"});
    }

    my XML::Element $td = append-element( $tr, 'td');
    $td.insert($_) for $content-body.nodes.reverse;
    $td.set( 'class', 'test-comment');

    if $todo {
      my XML::Element $b = insert-element( $td, 'b');
      my Str $t;
      $t = 'Next test is a todo test: ' if $todo-count == 1;
      $t = "Next $todo-count tests are todo tests: " if $todo-count > 1;
      insert-element( $b, :text($t));
    }

    else {
      # Prefix the comment with the test code
      my XML::Element $b = insert-element( $td, 'b');
      insert-element( $b, :text("D$!test-count: "));
    }
  }

  #-----------------------------------------------------------------------------
  method bug (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    die 'Cannot have bug here when still todo or bug lines are active'
      if $!todo-count or $!bug-count;

    my Int $test-code = $!test-count++;

    my Int $nbr-bugs = $attrs<n>:exists ?? $attrs<n>.Int !! 1;
    my Int $test-lines = $attrs<tl>:exists ?? $attrs<tl>.Int !! $nbr-bugs;
    $!bug-count = $test-lines;
say "BC: $!bug-count";
    self!bug-table(
      $parent, $attrs, :$content-body,
      :bug, :$nbr-bugs
    );

    my Str $code-text = "todo 'B$test-code', $nbr-bugs;\n";
    $!test-file-content ~= $code-text;
#`{{
    append-element( $last-defined-pre, :text("todo '"));
    my XML::Element $b = append-element( $last-defined-pre, 'b');
    append-element( $b, :text("B$test-code"));
    append-element( $last-defined-pre, :text("', $nbr-bugs;\n"));
}}
    $parent;
  }

  #-----------------------------------------------------------------------------
  method !bug-table ( 
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body,
    Bool :$bug = False,
    Int :$nbr-bugs = 1
  ) {

    my XML::Element $table = append-element(
      $parent, 'table', {class => 'test-table'}
    );

    my XML::Element $tr = append-element( $table, 'tr');
say "append check mark B$!test-count";

    # When handling todo, only show the comments and count of todo
    if $bug {
      append-element( $tr, 'td', {class => 'check-mark'});
    }

    # Test entries come here when todo counter is not zero
    else {
      append-element( $tr, '_CHECK_MARK_', {test-code => "B$!test-count"});
    }

    my XML::Element $td = append-element( $tr, 'td');
    $td.insert($_) for $content-body.nodes.reverse;
    $td.set( 'class', 'test-comment');

    if $bug {
      my XML::Element $b = insert-element( $td, 'b');
      my Str $t;
      $t = 'Next test is a bug issue test: ' if $nbr-bugs == 1;
      $t = "Next $nbr-bugs tests are bug issue tests: " if $nbr-bugs > 1;
      insert-element( $b, :text($t));
    }

    else {
      # Prefix the comment with the test code
      my XML::Element $b = insert-element( $td, 'b');
      insert-element( $b, :text("B$!test-count: "));
    }
  }
}

