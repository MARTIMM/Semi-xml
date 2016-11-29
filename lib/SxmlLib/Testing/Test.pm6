use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Test {

  enum TestType <Test Todo Bug Skip>;

  has Array $!parts = [];
  has Int $!count = 0;

  #-----------------------------------------------------------------------------
  method add (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

#say "T: ", ~$parent;
#say "B: ", ~$content-body;

    $!parts.push: {
      test-comment => $content-body,
      test-code => "$attrs<t>, 'T$!count'" // ''
    };

    my XML::Element $c = append-element( $parent, 'test');
    append-element( $c, :text($!count.Str));

#say $!parts.elems;
    $!count++;
    $parent;
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method make-table (
    XML::Element $parent, XML::Element :$content-body,
    TestType :$ttype, Bool :$tresult, Int :$tcount = 1
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

    my XML::Element $td = append-element( $tr, 'td');
    # ...

    $td = append-element( $tr, 'td');
    $td.insert($_) for $content-body.nodes.reverse;
    $td.set( 'class', 'test-comment');

    # Bold test code characters in front of test comment
    my XML::Element $b = insert-element( $td, 'b');
    my Str $t;
    given $ttype {

      # No need for special text on tests
      # when Test { }

      when Todo {
        $t = 'Next test is a todo test: ' if $tcount == 1;
        $t = "Next $tcount tests are todo tests: " if $tcount > 1;
        insert-element( $b, :text($t));
      }

      when Bug {
        $t = 'Next test is a bug issue test: ' if $tcount == 1;
        $t = "Next $tcount tests are bug issue tests: " if $tcount > 1;
        insert-element( $b, :text($t));
      }

      when Skip {
        $t = 'Next test is a skip test: ' if $tcount == 1;
        $t = "Next $tcount tests are skipped tests: " if $tcount > 1;
        insert-element( $b, :text($t));
      }
    }

    # Prefix the comment with the test code
    insert-element( $b, :text("$tcode$!count: "));
  }

  #-----------------------------------------------------------------------------
  method get-code-text ( Int $entry --> Str ) {

    $!parts[$entry]<test-code>;
  }
}
