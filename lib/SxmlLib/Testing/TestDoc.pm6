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
      $h1.insert(SemiXML::Text.new(:text($attrs<title>)));
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

say "$test-file, $!test-file-content";
    spurt( $test-file, $!test-file-content);

    # Run the test and get the result contents
    my Proc $p = run 'prove', '-e', 'perl6', '-vm',
                 '--rules=seq=*', $test-file, :out;

    # Store the data in a hash
    my Hash $test-results = {};
    my @lines = $p.out.lines;
    loop ( my $l = 0; $l < @lines.elems; $l++) {
      my $line = @lines[$l];

say "R: $line";

      # Get the test code if there is one
      $line ~~ m/ '-' \s* (.*) $/;
      my Str $test-code = $0.Str if ? $/;

      if ?$test-code {
say "TC: $test-code";
        if $line ~~ m:s/^ 'ok' / {

          if $test-results{$test-code} {
            $test-results{$test-code}[0]++;
          }

          else {
            $test-results{$test-code} = [ 1, 0];
          }
        }

        elsif $line ~~ m:s/^ 'not' 'ok' / {

          if $test-results{$test-code} {
            $test-results{$test-code}[1]++;
          }

          else {
            $test-results{$test-code} = [ 0, 1];
          }
        }
      }

      else {

      }
#say $test-code, ', ', $test-results{$test-code} if $test-code;
    }

#say $test-results.perl;

    # run tests and store in result file
    # read result file and map to a Hash
    #
    my $containers = $parent.getElementsByTagName('_CHECK_MARK_');
    for @$containers.reverse -> $node {
      my Str $test-code = $node.attribs<test-code>.Str;

      ( my Int $ok-c, my Int $nok-c) = @($test-results{$test-code} // [ 0, 0]);

# empty check box &#9744;

#say $test-code, ', ', $test-results{$test-code}, ", $ok-c, $nok-c";

      my XML::Element $td;
      if $ok-c {
        my SemiXML::Text $check-mark .= new(:text('&#10004;'));
        $td = before-element( $node, 'td', {class => 'check-mark green'} );
        $td.append($check-mark);
        $td.append(SemiXML::Text.new(:text("$ok-c "))) if $ok-c > 1;

        my $comment-td = $node.nextSibling;
        $comment-td.set( 'class', 'green test-comment') if ?$comment-td;
      }

      if $nok-c {
        my SemiXML::Text $check-mark .= new(:text('&#10008;'));

        my Bool $ok-td-exists = $td.defined;
        $td.set( 'class', 'smaller-check-mark green') if $ok-td-exists;

        $td = before-element( $node, 'td', {class => 'check-mark red'});
        $td.set( 'class', 'smaller-check-mark red') if $ok-td-exists;
        $td.append($check-mark);
        $td.append(SemiXML::Text.new(:text("$nok-c"))) if $nok-c > 1;

        my $comment-td = $node.nextSibling;
        if $ok-td-exists {
          $comment-td.set( 'class', 'purple test-comment') if ?$comment-td;
        }

        else {
          $comment-td.set( 'class', 'red test-comment') if ?$comment-td;
        }
      }

      # if neither --> todo

      $node.remove;
    }

    # remove hook
    $body.removeChild($hook);

    my XML::Element $div = append-element( $body, 'div', {class => 'footer'});

    $div.append(SemiXML::Text.new(:text(
#      "Generated using SemiXML::ver\(), SxmlLib::Testing::TestDoc, XML";
      "Generated using SemiXML, SxmlLib::Testing::TestDoc, XML";
    )));

    $parent;
  }

  #-----------------------------------------------------------------------------
  method doc (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    self!insert-title-and-text( $parent, $content-body, $attrs<title>//'', 'h2');

    $parent;
  }

  #-----------------------------------------------------------------------------
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
say "'$l'";
      $l ~~ s:g/^^ $indent //;
      $hook.after(SemiXML::Text.new(:text("$l\n")));
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

    self!test-table( $parent, $attrs, :$content-body);

    my Str $code-text = ($attrs<line> // '') ~ ", 'T{$!test-count++}';\n";
say "CT: $code-text";
    $!test-file-content ~= $code-text;

#    if $attrs<viz>:!exists or $attrs<viz> ne 'hide' {
      $last-defined-pre.append(SemiXML::Text.new(:text($code-text)));
#    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  method !setup-head ( XML::Element $head, Hash $attrs ) {

    if $attrs<title> {
      my XML::Element $title = append-element( $head, 'title');
      $title.insert(SemiXML::Text.new(:text($attrs<title>)));
    }

    my XML::Element $meta = append-element(
      $head, 'meta', {charset => 'UTF-8'}
    );

    my XML::Element $link = append-element(
      $head, 'link',
      { href => "file://%?RESOURCES<TestDoc.css>", rel => 'stylesheet'}
    );
  }

  #-----------------------------------------------------------------------------
  method !insert-title-and-text (
    XML::Element $parent,
    XML::Element $container,
    Str $title = '', Str $title-type = ''
  ) {

    my XML::Element $hook .= new(:name<hook>);
    $parent.insert($hook);

    if ?$title {
      my XML::Element $h .= new(:name($title-type));
      $h.insert(SemiXML::Text.new(:text($title)));
      $parent.before( $hook, $h);
    }

    $parent.after( $hook, $_) for $container.nodes.reverse;

    $parent.removeChild($hook);
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
#    if $attrs<viz>:!exists or $attrs<viz> ne 'hide' {
      $td.insert(SemiXML::Text.new(:text("T$!test-count: ")));
#    }
  }
}

