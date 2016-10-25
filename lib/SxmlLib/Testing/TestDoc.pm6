use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Testing::TestDoc {

  has Int $!test-count = 0;
  has Array $!tests = [];
  has Str $!test-file-content = Q:to/EOINIT/;
    use v6.c;
    use Test;

    EOINIT

  state Str $indent;

  #-----------------------------------------------------------------------------
  method report (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
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

    # Get all the test fields and modify it into a td element and insert
    # the according result from the file

    $!test-file-content ~= "\n\ndone-testing;\n";
say $!test-file-content;
    my $test-file = $attrs<test-file> // $*TMPDIR.Str;
    spurt( $test-file, $!test-file-content);
    my Proc $p = run 'prove', '-e', 'perl6', '-v', $test-file;
    #
    # run tests and store in result file
    # read result file and map to a Hash
    #
    my $containers = $parent.getElementsByTagName('_CHECK_MARK_');
    for @$containers.reverse -> $node {
      my Bool $ok = rand * 2.0 > 1.0 ?? True !! False;
      my Str $test-code = $node.attribs<test-code>;

# empty check box &#9744;

      if $ok {
        my SemiXML::Text $check-mark .= new(:text('&#10004;'));
        my XML::Element $td = before-element(
          $node, 'td', {class => 'check-mark green'}
        );
        $td.insert($check-mark);

        my $comment-td = $node.nextSibling;
        $comment-td.set( 'class', 'green test-comment') if ?$comment-td;
      }

      else {
        my SemiXML::Text $check-mark .= new(:text('&#10008;'));
        my XML::Element $td = before-element(
          $node, 'td', {class => 'check-mark red'}
        );
        $td.insert($check-mark);

        my $comment-td = $node.nextSibling;
        $comment-td.set( 'class', 'red test-comment') if ?$comment-td;
      }

      $node.remove;
    }

    # remove hook
    $body.removeChild($hook);

    $parent;
  }

  #-----------------------------------------------------------------------------
  method doc (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    self!insert-title-and-text( $parent, $attrs<title>, 'h2', $content-body);

    $parent;
  }

  #-----------------------------------------------------------------------------
  method code (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    my XML::Element $pre = append-element(
      $parent, 'pre',
      {:class<test-block-code>}
    );

    if not ?$indent {
      $indent = ($content-body.nodes[0] // '').Str;
      $indent ~~ s/^ (\s+) .* $/$0/;
    }

    for $content-body.nodes.reverse {
      my $l = ~$^a;
      $l ~~ s/^ $indent //;
      $pre.insert(SemiXML::Text.new(:text($l)));
    }

    for $pre.nodes -> $node {
      $!test-file-content ~= "$node\n";
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  method test (
    XML::Element $parent,
    Hash $attrs,
    XML::Element :$content-body
  ) {

    my Str $test-line = ($attrs<line> // '') ~  "'T{++$!test-count}'";
#    self!generate-test($test-line);
    self!test-table( $parent, $attrs, :$content-body);

    $!test-file-content ~= ($attrs<line> // '') ~ ", 'T{$!test-count}';\n";

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
    Str $title, Str $title-type,
    XML::Element $container
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
    append-element( $tr, '_CHECK_MARK_', {test-code => "'T$!test-count'"});
    my XML::Element $td = append-element( $tr, 'td');
    $td.insert($_) for $content-body.nodes.reverse;
  }

  #-----------------------------------------------------------------------------
  method !generate-test ( Str $test-line ) {

    
  }
}

