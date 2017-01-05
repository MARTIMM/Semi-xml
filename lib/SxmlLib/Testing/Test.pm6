use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
class Test {

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    my Int $count = $SxmlLib::Testing::count++;
    my Array $parts := $SxmlLib::Testing::parts;

    $parts.push: {
      comment => $content-body,
      code => "$attrs<t>, ",
      count => $count,
      label => 'T'
    };

    my XML::Element $c = append-element( $parent, 'test');
    append-element( $c, :text($count.Str));

    $parent;
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method make-table ( Int $entry --> XML::Element ) {

    my Array $parts := $SxmlLib::Testing::parts;
    my Str $test-label = $parts[$entry]<label> ~ $parts[$entry]<count>;

    my XML::Element $table .= new(:name<table>);
    $table.set( 'class', 'test-table');

    # table of one row
    my XML::Element $tr = append-element( $table, 'tr');

    # First data field cannot yet be filled in. Place a findable mark in it
    # with the type label and count
    my XML::Element $cm = append-element( $tr, '__CHECK_MARK__');
    $cm.set( 'test-code', $test-label);

    # Second data field
    my XML::Element $td = append-element( $tr, 'td');
    $td.insert($_) for $parts[$entry]<comment>.nodes.reverse;
    $td.set( 'class', 'test-comment');

    # Bold test code characters in front of test comment
    my XML::Element $b = insert-element( $td, 'b');

    # Prefix the comment with the test code
    insert-element( $b, :text("$test-label: "));

    $table;
  }

  #-----------------------------------------------------------------------------
  method get-code-text ( Int $entry --> Str ) {

    my Array $parts := $SxmlLib::Testing::parts;
    my Str $code = $parts[$entry]<code>;
    given $SxmlLib::Testing::current-type {
      when TestCmd {
        $code ~= "'T$parts[$entry]<count>';";
        $parts[$entry]<label> = 'T';
      }

      when TodoCmd {
        $code ~= "'D$parts[$entry]<count>';";
        $parts[$entry]<label> = 'D';
      }

      when BugCmd {
        $code ~= "'B$parts[$entry]<count>';";
        $parts[$entry]<label> = 'B';
      }

      when SkipCmd {
        $code ~= "'S$parts[$entry]<count>';";
        $parts[$entry]<label> = 'S';
      }
    }

    # lower type counter and reset to TestCmd if 0
    if $SxmlLib::Testing::type-count {
      $SxmlLib::Testing::type-count--;
      $SxmlLib::Testing::current-type = TestCmd
        unless $SxmlLib::Testing::type-count
    }

    $code;
  }
}
