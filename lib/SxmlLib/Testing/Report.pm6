use v6.c;
use SemiXML;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

#-------------------------------------------------------------------------------
class Report {

  has $!code-obj;
  has $!test-obj;
  has $!todo-obj;

  has XML::Element $!report-doc;
  has XML::Element $!body;
  
  has Str $!test-program;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $sxml, Hash $attrs ) {

say "\nInit report: ";
for $attrs.kv -> $k, $v { say "$k => $v" };
print "\n";

    $!test-program = Q:to/EOINIT/;
      use v6.c;
      use Test;

      EOINIT

    $!code-obj = $sxml.get-sxml-object('SxmlLib::Testing::Code');
    $!test-obj = $sxml.get-sxml-object('SxmlLib::Testing::Test');
    $!todo-obj = $sxml.get-sxml-object('SxmlLib::Testing::Todo');

    self!setup-report-doc($attrs);
  }

  #-----------------------------------------------------------------------------
  method run (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

#say "R: $parent";
#say "B: ", ~$content-body;

    # Fill body with results. Eat from the end of the list and add just after
    # the container element. Somehow they get lost from the array when done
    # otherwise.
    #
    # Place a hook to work with
#    my XML::Element $hook = append-element( $!body, 'hook');
#    $hook.after($_) for $content-body.nodes.reverse;
#    $!body.removeChild($hook);

    # setup the report document with check mark elements to be replaced later
    # by the results from the prove run
    self!report-template(:$content-body);



say "\n\nCode:\n$!test-program";

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

              # Add test to the <pre> block
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
}



