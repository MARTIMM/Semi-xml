use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML::Sxml;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
class Report:ver<0.2.1> {

  has $!sxml;

  has $!code-obj;
  has $!test-obj;
  has $!todo-obj;
  has $!bug-obj;
  has $!skip-obj;

  has XML::Element $!report-doc;
  has XML::Element $!body;

  has Str $!test-program;

  # Storage of test results. Key is the test code which is like T##/D##. The
  # value is an Array of which the 1st element is the success count and the
  # 2nd the failure count. These are counts so it can be used to do tests in
  # a loop.
  has Hash $!test-results;

  # Storage of all scored test results per test type. The test type is same as
  # the test code without the digits. So type 'T', 'D', etc.
  has Hash $!test-metrics;

  # Gathered data from $!test-metrics to show in pie-charts
  has Array $!all-metrics = [];

  # When metrics file is read, some data is stored here
  has Hash $env-metrics = {};

  has Bool $!highlight-code = False;
  has Str $!highlight-language = '';
  has Str $!highlight-skin = '';
  has Bool $!linenumbers = False;
  has Int $!line-number;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $sxml, Hash $attrs ) {

    $!sxml = $sxml;

    $!test-program = Q:to/EOINIT/;
      use v6;
      use Test;

      EOINIT
    $!line-number = 4;

    $!code-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Code');
    $!test-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Test');
    $!todo-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Todo');
    $!bug-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Bug');
    $!skip-obj = $!sxml.get-sxml-object('SxmlLib::Testing::Skip');

    $!highlight-code = ?$attrs<highlight-lang> // False;
    $!highlight-language = $attrs<highlight-lang> // '';
    $!highlight-skin = lc($attrs<highlight-skin> // 'prettify');
    $!highlight-skin = $!highlight-skin eq 'default'
                       ?? 'prettify' !! $!highlight-skin;
    $!linenumbers = ?$attrs<linenumbers> // False;

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
      $div,
      :text("Generated using SemiXML, SxmlLib::Testing::*, XML, &copy;Google prettify")
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

    my XML::Element $html = append-element( $parent, 'html');
    my Str $title = $attrs<title> // '';
    my XML::Element $head = append-element( $html, 'head');
    self!setup-head( $head, $attrs);
    my XML::Element $body = append-element( $html, 'body');

    $body.append($content-body);
    $parent;
  }

  #-----------------------------------------------------------------------------
  method metrics (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list
    --> XML::Node
  ) {

    my Str $metric-dir = $attrs<metric-dir> // '.';
    my @metric-files = dir($metric-dir).grep(/t.metric/);
    for @metric-files -> $mf {
      self!load-metrics($mf);

#note "T: ", $!test-metrics;
note "A: ", $!all-metrics;
#note "M: ", $!env-metrics;
      my XML::Element $table = append-element(
        $parent, 'table', %(:class<summary-table>)
      );

      my XML::Element $tr = append-element( $table, 'tr');
      append-element(
        $tr, 'th', %(:colspan<3>,),
        :text($!env-metrics<Title>[0])
      );

      $tr = append-element( $table, 'tr');
      append-element(
        $tr, 'th', %(:class<summary-header>,), :text("Date (zulu)")
      );

      append-element( $tr, 'td', :text(now.DateTime.utc.Str));
      my XML::Element $summ-dt = append-element(
        $tr, 'td', %( :class<summary-pie>, :rowspan<7>)
      );
      self!summary-pie(
        $summ-dt, $!all-metrics[0],
        ([+] $!all-metrics[1], $!all-metrics[4], $!all-metrics[7]),
        $!all-metrics[2], $!all-metrics[5], $!all-metrics[8],
        $!all-metrics[12]
      ) if $!all-metrics[0];

      $tr = append-element( $table, 'tr');
      append-element( $tr, 'th', %(:class<summary-header>,), :text<Distribution>);
      append-element( $tr, 'td', :text($!env-metrics<Distribution>[0]));

      $tr = append-element( $table, 'tr');
      append-element( $tr, 'th', %(:class<summary-header>,), :text<Packages>);
      append-element( $tr, 'td', :text($!env-metrics<Package>[0]));

      $tr = append-element( $table, 'tr');
      append-element( $tr, 'th', %(:class<summary-header>,), :text<Modules>);
      append-element( $tr, 'td', :text($!env-metrics<Module>[0]));

      $tr = append-element( $table, 'tr');
      append-element( $tr, 'th', %(:class<summary-header>,), :text<Classes>);
      append-element( $tr, 'td', :text($!env-metrics<Class>[0]));

      $tr = append-element( $table, 'tr');
      append-element( $tr, 'th', %(:class<summary-header>,), :text<Os>);
      append-element(
        $tr, 'td', :text($!env-metrics<OS-Distro>[0..2].join(' '))
      );

      $tr = append-element( $table, 'tr');
      append-element( $tr, 'th', %(:class<summary-header>,), :text<Compiler>);
      append-element(
        $tr, 'td', :text(
          $!env-metrics<Perl>[*].join(' ') ~ ', ' ~
          $!env-metrics<Compiler>[*].join(' ') ~ ', ' ~
          $!env-metrics<VM>[*].join(' ')
        )
      );
    }

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
    $!body.set( 'onload', 'prettyPrint()') if $!highlight-code;


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

    if $!highlight-code {

      # temporary check of RESOURCES path when using uninstalled version
note "C: ", %?RESOURCES<google-code-prettify/desert.css>;
      my $css = %?RESOURCES{"google-code-prettify/$!highlight-skin.css"}.Str;
$css ~~ s/ 'Projects/resources' /Projects\/Semi-xml\/resources/;
#say "Pretty css: $css";

      append-element(
        $head, 'link', {
          :href("file://$css"),
          :type<text/css>, :rel<stylesheet>
        }
      );

      my Str $js = %?RESOURCES<google-code-prettify/prettify.js>.Str;
$js ~~ s/ 'Projects/resources' /Projects\/Semi-xml\/resources/;
#say "pretty js: $js";
      my XML::Element $jse = append-element(
        $head, 'script', { :src("file://$js"), :type<text/javascript>}
      );
      append-element( $jse, :text(' '));
    }

    my $css = %?RESOURCES<report.css>.Str;
$css ~~ s/ 'Projects/resources' /Projects\/Semi-xml\/resources/;
#say "Css report: $css";
    append-element(
      $head, 'link', {
        :href("file://$css"),
        :type<text/css>, :rel<stylesheet>
      }
    );
  }

  #-----------------------------------------------------------------------------
  method !report-template ( XML::Element :$content-body ) {

    my XML::Element $hook;
    my XML::Element $pre;

    my @nodes = $content-body.nodes;
    while @nodes {

      my $node = @nodes.shift;

      # check the start of code sections
      if $node ~~ XML::Element
         and $node.name eq '__PARENT_CONTAINER__'
         and $node.nodes[0].name eq 'code' {

        # <pre> used to display code in
        my Str $class = 'test-block-code';
        if $!highlight-code {
          $class = "prettyprint $!highlight-language";
          if $!linenumbers {
            $class ~= " linenums:$!line-number";
          }
        }

        $pre = append-element( $!body, 'pre', {:$class});

        # <hook> used to insert test, todo, bug and skip content after the code.
        # $hook is removed later
        #
        $hook = append-element( $!body, 'hook');


        # get code entry number
        my Int $centry = ([~] $node.nodes[0].nodes).Int;

        # get the nodes stored in the code section
        my @code-nodes = $!code-obj.get-code-part($centry).nodes;
        while +@code-nodes {

          my $code-node = shift @code-nodes;

          # test sections must be translated in code and also inserted just
          # after this <pre> section
          #
          my XML::Element $x;
          $x = $code-node.nodes[0]
             if $code-node ~~ XML::Element
                and $code-node.name eq '__PARENT_CONTAINER__';

          if ? $x {
            my Int $tentry = ([~] $code-node[0].nodes).Int;
            if $x.name eq 'test' {

              # get test entry number 
              my Str $code-text = self!process-code(~$!test-obj.get-code-text($tentry));

              # add test to the <pre> block
              append-element( $pre, :text($code-text));

              # and to the test program
              $!test-program ~= $code-text;

              # add test text after the <pre> and before the <hook>
              $!body.before( $hook, $!test-obj.make-table($tentry));
            }

            elsif $x.name eq 'todo' {

              # get test entry number 
              my Str $code-text = self!process-code(~$!todo-obj.get-code-text($tentry));

              # add todo to the <pre> block
              append-element( $pre, :text($code-text));

              # and to the test program
              $!test-program ~= $code-text;

              # add todo text after the <pre> and before the <hook>
              $!body.before( $hook, $!todo-obj.make-table($tentry));
            }

            elsif $x.name eq 'bug' {

              # get test entry number 
              my Str $code-text = self!process-code(~$!bug-obj.get-code-text($tentry));

              # add bug issue to the <pre> block
              append-element( $pre, :text($code-text));

              # and to the test program
              $!test-program ~= $code-text;

              # add bug text after the <pre> and before the <hook>
              $!body.before( $hook, $!bug-obj.make-table($tentry));
            }

            elsif $x.name eq 'skip' {

              # get test entry number 
              my Str $code-text = self!process-code(~$!skip-obj.get-code-text($tentry));

              # add skip to the <pre> block
              append-element( $pre, :text($code-text));

              # and to the test program
              $!test-program ~= $code-text;

              # add skip text after the <pre> and before the <hook>
              $!body.before( $hook, $!skip-obj.make-table($tentry));
            }
          }

          # $x not defined so it is plain code text
          else {

            my Str $code-text = self!process-code(~$code-node);
            append-element( $pre, :text($code-text)) if ?$code-text;
            $!test-program ~= $code-text if ?$code-text;
          }
        }
      }

      # anything else is text/nodes
      else {
        $!body.append($node);
      }
    }

    # Cannot use $!body.removeChild($hook) because in the mean time there
    # are many hooks left behind, so search by name
    for $!body.nodes.reverse -> $node {
      $node.remove if $node.name eq 'hook';
    }
  }

  #-----------------------------------------------------------------------------
  method !process-code ( Str $code-text is copy --> Str ) {

    state Int $indent-level = 0;
    state Int $prev-indent-level = 0;
    constant INDENT-STEP = 4;
    my Str $code = '';

    # insert newline after any closing curly bracket
    $code-text ~~ s:g/ '}' <!before <[\n;,]>>/}\n/;

    # split code script on every line
    for $code-text.split(/\n/) {
      # clean line for leading and trailing spaces
      my Str $line = $^a;
      $line ~~ s/^ \h+ //;
      $line ~~ s/ \s+ $ //;

      # skip empty lines
      next unless ? $line;

      # count open brackets to increment level
      $indent-level += ($line ~~ m:g/<[\[\(\{]>/).elems;

      # count close brackets to decrement level
      $indent-level -= ($line ~~ m:g/<[\]\)\}]>/).elems;

      # if indent-level is decreased then use new indent
      if $prev-indent-level > $indent-level {
        $code ~= ' ' x ($indent-level * INDENT-STEP) ~ $line ~ "\n";
        $prev-indent-level = $indent-level;
      }

      # if indent-level is increased then use previous indent first
      else {
        $code ~= ' ' x ($prev-indent-level * INDENT-STEP) ~ $line ~ "\n";
        $prev-indent-level = $indent-level;
      }

      $!line-number++;
    }

    $code;
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
    $!test-program ~= "\ndone-testing;\n";

    # get a filename for the tests and write
    my $test-file = $attrs<test-file>;
    $test-file //= ($!sxml.get-current-filename ~ '.t');
    $test-file //= ($*TMPDIR.Str ~ '/perl6-test.t');

    spurt( $test-file, $!test-program);

    # run the tests using prove and get the result contents through a pipe
#    my Proc $p = run 'prove', '--exec', 'perl6', '--verbose', '--merge',
    my Proc $p = run 'prove', '--exec', 'perl6', '--verbose',
                 '--rules=seq=*', "--lib", $test-file, :out;
    # read lines from pipe from testing command
    my @lines = $p.out.lines;

    # tail of the test results
    my Bool $save-summary = False;
    my Str $prove-summary-text = '';

    say "\n---[Prove output]", '-' x 63;
    loop ( my $l = 0; $l < @lines.elems; $l++) {
      my $line = @lines[$l];
      say "$line";

      if $line ~~ m:s/^ 'Test' 'Summary' 'Report' / or $save-summary {
        $save-summary = True;
        $prove-summary-text ~= $line;
        next;
      }

      # get the test code if there is one.
      $line ~~ m/ '-' \s* (<[TDBS]> \d+) /;
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

      # check skipped code
      elsif $line ~~ m/'# SKIP' \s* ('S' \d+) $/ {
        my Str $test-code2 = $0.Str if ? $/;
        self!set-test-results( $test-code2, $ok, :metric);
      }

      elsif $test-code {
        $test-code ~~ s/^ 'S' /T/;
        self!set-test-results( $test-code, $ok, :metric);
      }
    }

    say "---[End prove output]", '-' x 59;
    say " ";

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

    $metric-text ~= "Date (zulu):" ~ now.DateTime.utc.Str ~ "\n";

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
    $ts = [+] @($!test-metrics<S>[0]);
    $!all-metrics.push: $!test-metrics<S>[0], $!test-metrics<S>[1], $ts;
    $metric-text ~= ("S", $!all-metrics[10..12].fmt('%.2f')).join(':') ~ "\n";

    spurt( $metric-file, $metric-text);
  }

  #-----------------------------------------------------------------------------
  # load metric file.and set $!env-metrics and $!all-metrics
  method !load-metrics ( IO::Path:D $test-file ) {

    $!env-metrics = {};
    for $test-file.slurp.lines -> $metric {
      # Split on colons but not double colons in case of modulenames
      my @mdata = $metric.split(/':' <!before ':'>/);
      my $key = shift @mdata;
      given $key {
        when /^ <[TBDS]> $/ {
          my @m = @mdata.split(' ');
note "\@m: ", @m;
          $!test-metrics{$key} = [ @m[0].Int, @m[1].Int];
        }

        default {
          $!env-metrics{$key} = @mdata;
        }
      }
    }

    my Int $total =
      [+] |@($!test-metrics<T>), |@($!test-metrics<B>),
          |@($!test-metrics<D>), |@($!test-metrics<S>);
    $!all-metrics = [$total];

    my Int $ts = [+] @($!test-metrics<T>);
    $!all-metrics.push: $!test-metrics<T>[0], $!test-metrics<T>[1], $ts;

    $ts = [+] @($!test-metrics<B>);
    $!all-metrics.push: $!test-metrics<B>[0], $!test-metrics<B>[1], $ts;

    $ts = [+] @($!test-metrics<D>);
    $!all-metrics.push: $!test-metrics<D>[0], $!test-metrics<D>[1], $ts;

    $ts = [+] @($!test-metrics<S>[0]);
    $!all-metrics.push: $!test-metrics<S>[0], $!test-metrics<S>[1], $ts;
  }

  #-----------------------------------------------------------------------------
  method !process-test ( ) {

    # search for special elements left and modify these
    my Array $containers = $!report-doc.getElementsByTagName('__CHECK_MARK__');
    for @$containers.reverse -> $node {

      my Str $test-code = $node.attribs<test-code>.Str;

      my Int $ok-c;
      my Int $nok-c;
      ( $ok-c, $nok-c) = @($!test-results{$test-code} // [ 0, 0]);

      # when skip statements are executed, the metrics will be counted under
      # the T## test metric. So, when there is no info and the test-code was a
      # skip code, try to get it from the T## entry
      #
      if !$ok-c and !$nok-c and $test-code ~~ m/^ 'S' / {
        my $tc = $test-code;
        $tc ~~ s/^ 'S' /T/;
        ( $ok-c, $nok-c) = @($!test-results{$tc} // [ 0, 0]);
      }
#say "TR: $test-code, $ok-c, $nok-c";

      my XML::Element $td;
      if $ok-c {
        $td = before-element( $node, 'td', {class => 'check-mark green'} );

        # check mark todo ok is an empty sheet symbol
        if $test-code ~~ m/^ 'D' / {
          append-element( $td, :text('&#128459;'));
        }

        # check mark bug issue ok is an empty sheet symbol
        elsif $test-code ~~ m/^ 'B' / {
          append-element( $td, :text('&#128459;'));
        }

        # check mark skip but ok is a check mark symbol
        elsif $test-code ~~ m/^ 'S' / {
          append-element( $td, :text('&#10004;'));
        }

        # check mark test ok is a check mark symbol
        else {
          append-element( $td, :text('&#10004;'));
        }

        append-element( $td, :text("$ok-c ")) if $ok-c > 1;
      }

      if $nok-c {
        # if multiple tests are done on the same testline (e.g. loops)
        # make the <td> smaller and add another one
        #
        my Bool $ok-td-exists = $td.defined;
        $td.set( 'class', 'smaller-check-mark green') if $ok-td-exists;

        # the other being the not ok <td>
        $td = before-element( $node, 'td', {class => 'check-mark red'});
        $td.set( 'class', 'smaller-check-mark red') if $ok-td-exists;

        # check mark todo nok is a written sheet symbol
        if $test-code ~~ m/^ 'D' / {
          append-element( $td, :text('&#128462;'));
        }

        # check mark bug issue nok is a written sheet symbol
        elsif $test-code ~~ m/^ 'B' / {
          append-element( $td, :text('&#128462;'));
        }

        # check mark skip but nok is a cross symbol
        elsif $test-code ~~ m/^ 'S' / {
          append-element( $td, :text('&#10008;'));
        }

        # check mark test nok is a cross symbol
        else {
          append-element( $td, :text('&#10008;'));
        }

        append-element( $td, :text("$nok-c ")) if $nok-c > 1;
      }

      # Skipped tests
      if not $ok-c and not $nok-c {
        my Bool $ok-td-exists = $td.defined;
        $td.set( 'class', 'smaller-check-mark green') if $ok-td-exists;

        $td = before-element( $node, 'td', {class => 'check-mark red'});
        $td.set( 'class', 'smaller-check-mark red') if $ok-td-exists;
        append-element( $td, :text('&#x2728;'));
      }

      $node.remove;
    }
  }

  #-----------------------------------------------------------------------------
  # Gather results of a test. $test-code is a letter code 'T', 'S', 'B' etc.
  # with the test number attached e.g 'T3'.
  # $ok is True or False for the test result. Must return when undefined.
  # $metric controls storage. Not all data must be saved or they will be
  # duplicated.
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

    # Setup a table data field with svg element in it
    my XML::Element $td = append-element( $tr, 'td');
    self!summary-pie(
      $td, $!all-metrics[0],
      ([+] $!all-metrics[1], $!all-metrics[4], $!all-metrics[7]),
      $!all-metrics[2], $!all-metrics[5], $!all-metrics[8],
      $!all-metrics[12]
    ) if $!all-metrics[0];
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

    # colored rectangles with count and text
    self!rectangle( $g, $class ~ '-ok', 0, 0, $ok);
    self!rectangle( $g, $class ~ '-nok', 0, 15, $nok);

    # draw a line
    append-element(
      $g, 'path', { class => 'line', d => 'M 0 28 H 40' }
    );

    self!rectangle( $g, '', 0, 30, $ntests, :!rectangle);
  }

  #-----------------------------------------------------------------------------
  method !summary-pie (
    XML::Element $parent, Int $total, Int $all-ok,
    Int $test-nok, Int $bug-nok, Int $todo-nok, Int $skip
  ) {

    my XML::Element $svg = append-element(
      $parent, 'svg', {
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
      $g, 'path', { class => 'line', d => 'M 0 73 H 80' }
    );

    self!rectangle( $g, '', 0, 75, $total, :text<Total>, :!rectangle);
  }

  #-----------------------------------------------------------------------------
  method !rectangle (
    XML::Element $g, Str $class, Int $x, Int $y, Int $count, Str :$text,
    Bool :$rectangle = True
  ) {

    if $rectangle {
      append-element(
        $g, 'rect', {
          class => $class,
          x => $x.Str, y => $y.Str,
          width => '15', height => '10'
        }
      );
    }

    my XML::Element $t = append-element(
      $g, 'text', { class => 'legend', x => ($x + 20).Str, y => ($y + 10).Str}
    );

    append-element( $t, :text("$count"));

    if ? $text {
      $t = append-element(
        $g, 'text', { class => 'legend', x => ($x + 40).Str, y => ($y + 10).Str}
      );
      append-element( $t, :$text);
    }
  }
}



