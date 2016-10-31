use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Testing::TestDoc {

  # The test counter is used to generate a description messages with each test
  # like 'T##'. This is also stored in the element _CHECK_MARK_ with a
  # 'test-code' attribute.
  has Int $!test-count = 0;

  # Initialize the test file with a few lines
  has Str $!test-file-content = Q:to/EOINIT/;
    use v6.c;
    use Test;

    EOINIT

  state Str $indent;
  has XML::Element $last-defined-pre;
  has Hash $!test-results;

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

    # Run the test and get the result contents
    my Proc $p = run 'prove', '-e', 'perl6', '-vm',
                 '--rules=seq=*', $test-file, :out;

    # Store the data in a hash
    $!test-results = {};
    my @lines = $p.out.lines;
    loop ( my $l = 0; $l < @lines.elems; $l++) {
      my $line = @lines[$l];

say "R: $line";

      # get the test code if there is one
      $line ~~ m/ '-' \s* ('T' \d+) /;
      my Str $test-code = $0.Str if ? $/;
      my Any $ok = $line ~~ m:s/^ 'ok' /
                   ?? True
                   !! ( $line ~~ m:s/^ 'not' 'ok' /
                        ?? False
                        !! Any
                      );
      self!set-test-results( $test-code, $ok);

      # check todo
      if $line ~~ m/'# TODO' \s* ('T' \d+) $/ {
        $test-code = $0.Str if ? $/;
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

# empty check box &#9744;
      my XML::Element $td;
      if $ok-c {
        $td = before-element( $node, 'td', {class => 'check-mark green'} );
        append-element( $td, :text('&#10004;'));
        append-element( $td, :text("$ok-c ")) if $ok-c > 1;

        my $comment-td = $node.nextSibling;
        $comment-td.set( 'class', 'test-comment') if ?$comment-td;
      }

      if $nok-c {
        my Bool $ok-td-exists = $td.defined;
        $td.set( 'class', 'smaller-check-mark green') if $ok-td-exists;

        $td = before-element( $node, 'td', {class => 'check-mark red'});
        $td.set( 'class', 'smaller-check-mark red') if $ok-td-exists;
        append-element( $td, :text('&#10008;'));
        append-element( $td, :text("$nok-c")) if $nok-c > 1;

        my $comment-td = $node.nextSibling;
        $comment-td.set( 'class', 'test-comment') if ?$comment-td;
      }

      $node.remove;
    }

    # remove hook
    $body.removeChild($hook);

    my XML::Element $div = append-element( $body, 'div', {class => 'footer'});

    append-element( $div, :text(
#      "Generated using SemiXML::ver\(), SxmlLib::Testing::TestDoc, XML";
      "Generated using SemiXML, SxmlLib::Testing::TestDoc, XML";
    ));

    $parent;
  }

  #-----------------------------------------------------------------------------
  method !set-test-results ( Str $test-code, Any $ok ) {

    return unless ?$test-code and $ok.defined and $ok ~~ Bool;

    if $ok {

      if $!test-results{$test-code} {
        $!test-results{$test-code}[0]++;
      }

      else {
        $!test-results{$test-code} = [ 1, 0];
      }
    }

    else {

      if $!test-results{$test-code} {
        $!test-results{$test-code}[1]++;
      }

      else {
        $!test-results{$test-code} = [ 0, 1];
      }
    }
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

    self!test-table( $parent, $attrs, :$content-body);

    my Int $test-code = $!test-count++;

    my Int $nbr-todo;
    my Str $code-text = ($attrs<line> // '');
    if $code-text ~~ m/^ todo/ {
      if $code-text ~~ m/ (\d+) $/ {
        $nbr-todo = $0.Str.Int;
      }

      else {
        $nbr-todo = 1;
      }

      $code-text = "todo 'T$test-code', $nbr-todo;\n";
      $!test-file-content ~= $code-text;

      append-element( $last-defined-pre, :text("todo '"));
      my XML::Element $b = append-element( $last-defined-pre, 'b');
      append-element( $b, :text("T$test-code"));
      append-element( $last-defined-pre, :text("', $nbr-todo;\n"));
    }

    elsif ? $code-text {

      $code-text ~= ",";
      my $line = $code-text;
      $code-text ~= " 'T$test-code';\n";
      $!test-file-content ~= $code-text;

  #    my $line = $attrs<line> // '';
  #    $line ~= "," unless $line ~~ m/^ todo/;
      $line ~= " '";

      append-element( $last-defined-pre, :text($line));
      my XML::Element $b = append-element( $last-defined-pre, 'b');
      append-element( $b, :text("T$test-code"));
      append-element( $last-defined-pre, :text("';\n"));
    }


    $parent;
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

    # Prefix the comment with the test code
    my XML::Element $b = insert-element( $td, 'b');
    insert-element( $b, :text("T$!test-count: "));
  }
}

