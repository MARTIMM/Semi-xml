use v6.c;
use SemiXML;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Todo {

  has Array $!parts = [];

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

#say "T: ", ~$parent;
#say "B: ", ~$content-body;

say "todo: $attrs<n>, 'D$count'";
    $parts.push: {
      comment => $content-body,
      code => "todo D$count, $test-lines",
      lines => $test-lines,
      count => $count,
      label => 'D'
    };

    my XML::Element $c = append-element( $parent, 'todo');
    append-element( $c, :text($count.Str));

    $parent;
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method make-table ( Int $entry --> XML::Element ) {

say "make table todo entry $entry";
    my Array $parts := $SxmlLib::Testing::parts;
    my Int $count = $parts[$entry]<count>;
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

    # Bold test code characters in front of test comment
    my XML::Element $b = insert-element( $td, 'b');
    my Str $t;
    if $count > 1 {
      $t = "Next $count tests (D{$entry+1}-{$entry+$count} are todo tests: ";
    }
    
    else {
      $t = "Next D{$entry+1} test is a todo test: ";
    }
    insert-element( $b, :text($t));

#   insert-element( $b, :text('Next B## tests are bug issue tests: '));
#   insert-element( $b, :text('Next S## tests are skipped tests: '));

    # Prefix the comment with the test code
#    insert-element( $b, :text("$test-label: "));
say "todo table: ", ~$table;
    $table;
  }

  #-----------------------------------------------------------------------------
  method get-code-text ( Int $entry --> Str ) {

    my Array $parts := $SxmlLib::Testing::parts;
    $SxmlLib::Testing::current-type = TodoCmd;
    $SxmlLib::Testing::type-count = $parts[$entry]<lines>;

    $parts[$entry]<code>;
  }
}

