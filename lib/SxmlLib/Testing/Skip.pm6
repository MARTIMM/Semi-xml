use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
class Skip {

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    my Int $count = $SxmlLib::Testing::count++;
    my Array $parts := $SxmlLib::Testing::parts;
    my Int $test-lines = $attrs<tl>:exists
                 ?? $attrs<tl>.Int
                 !! ($attrs<n>:exists ?? $attrs<n>.Int !! 1);

    $parts.push: {
      comment => $content-body,
      code => "skip 'S$count', $test-lines;",
      lines => $test-lines,
      count => $count,
      label => 'S'
    };

    my XML::Element $c = append-element( $parent, 'skip');
    append-element( $c, :text("$count"));

    $parent;
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method make-table ( Int $entry --> XML::Element ) {

    my Array $parts := $SxmlLib::Testing::parts;
    my Int $count = $parts[$entry]<count>;
    my Int $lines = $parts[$entry]<lines>;
    my Str $test-label = "$parts[$entry]<label>$count";

    my XML::Element $table .= new(:name<table>);
    $table.set( 'class', 'test-table');

    # table of one row
    my XML::Element $tr = append-element( $table, 'tr');

    # first data field is not filled in.
    my XML::Element $td = append-element( $tr, 'td');

    # second data field
    $td = append-element( $tr, 'td');
    $td.set( 'class', 'check-mark');
    $td.insert($_) for $parts[$entry]<comment>.nodes.reverse;
    $td.set( 'class', 'test-comment');

    # bold test code characters in front of test comment
    my XML::Element $b = insert-element( $td, 'b');
    my Str $t;
    if $lines > 1 {
      $t = "Next $lines tests (S{$entry+1}-{$entry+$lines}) might be skipped: ";
    }

    else {
      $t = "Next S{$entry+1} test might be skipped: ";
    }
    insert-element( $b, :text($t));

    $table;
  }

  #-----------------------------------------------------------------------------
  method get-code-text ( Int $entry --> Str ) {

    my Array $parts := $SxmlLib::Testing::parts;
    $SxmlLib::Testing::current-type = SkipCmd;
    $SxmlLib::Testing::type-count = $parts[$entry]<lines>;

    $parts[$entry]<code>;
  }
}

