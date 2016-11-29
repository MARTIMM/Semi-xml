use v6.c;
use SemiXML;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

my Array $xml-parts = [ ];
my Array $code-parts = [ ];

#-------------------------------------------------------------------------------
class Report {

  has $!test-obj;
  has $!code-obj;

  has XML::Element $!report-doc;
  has XML::Element $!body;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $sxml, Hash $attrs ) {

say "\nInit report: ";
for $attrs.kv -> $k, $v { say "$k => $v" };
print "\n";

    $!code-obj = $sxml.get-sxml-object('SxmlLib::Testing::Code');
    $!test-obj = $sxml.get-sxml-object('SxmlLib::Testing::Test');

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
    my XML::Element $pre;

    # Fill body with results. Eat from the end of the list and add just after
    # the container element. Somehow they get lost from the array when done
    # otherwise.
    #
    # Place a hook to work with
#    my XML::Element $hook = append-element( $!body, 'hook');
#    $hook.after($_) for $content-body.nodes.reverse;
#    $!body.removeChild($hook);

    my @nodes = $content-body.nodes;
    while @nodes {

      my $node = @nodes.shift;
say "\nN: ", $node.WHAT;
      if $node ~~ XML::Element and $node.name eq '__PARENT_CONTAINER__' {

say $node.name;
        my @pc-nodes = $node.nodes;
        while @pc-nodes {

          my $pc-node = @pc-nodes.shift;
say "\nX: ", $pc-node.WHAT;
          if $pc-node ~~ XML::Element and $pc-node.name eq 'code' {
            $pre = append-element( $!body, 'pre', {:class<test-block-code>});

            # get code entry count
            my Int $centry = ([~] $pc-node.nodes).Int;
say "code $centry";
            my @code-nodes = $!code-obj.get-code-part($centry).nodes;
            while @code-nodes {
              my $code-node = shift @code-nodes;
              if $code-node ~~ XML::Element and $pc-node.name eq 'test' {
                # get test entry count
                my Int $tentry = ([~] $code-node.nodes).Int;
say "test $tentry, ", $!test-obj.get-code-text($tentry);
                $pre.append($!test-obj.get-code-text($tentry));
              }
              
              else {
                $pre.append($code-node);
              }
            }
          }
        }
      }
      
      else {
        $!body.append($node);
      }
    }

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
}

