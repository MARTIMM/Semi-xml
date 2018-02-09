use v6;
use Test;

use SemiXML::Node;
use SemiXML::Element;

#--------------------------------------------------------------------------
subtest 'Parent and children', {

  my SemiXML::Element $ep .= new(
    :name<ep>, :attributes({ a=>1, b=>2, 'sxml:inline' => 1})
  );
  my SemiXML::Element $ec1 .= new(
    :name<e1>, :attributes({ a=>1, b=>2}), :parent($ep)
  );

  is $ep.attributes<a>, 1, 'attribute a found';
  is $ep.attributes<b>, 2, 'attribute b found';
  is $ep.attributes<sxml:inline>, 1, 'attribute sxml:inline found';

  is $ep.name, 'ep', 'name of parent is ep';
  is $ec1.name, 'e1', 'name of child $ec1 is e1';

  ok $ec1.inline, 'inline inherited from parent';
  is $ec1.parent, $ep, "parent found of $ec1.name()";
}

#--------------------------------------------------------------------------
subtest 'Append, insert, before', {

  my SemiXML::Element $ep .= new(:name<ep>);
  my SemiXML::Element $ec1 .= new( :name<e1>, :parent($ep));

  my SemiXML::Element $ec2 .= new(:name<e2>);
  $ep.append($ec2);
  is $ec2.parent, $ep, 'parent found of ec2';

  is $ep.nodes[0], $ec1, "first child $ec1.name() found in parent";
  is $ep.nodes[1], $ec2, "second child $ec1.name() found in parent";

  my SemiXML::Element $ec3 .= new(:name<e3>);
  $ep.before( $ec1, $ec3);
  is $ep.nodes[0], $ec3, "first child now $ec3.name(), before";

  my SemiXML::Element $n = $ec3.remove;
  is $n, $ec3, 'node e3 returned';
  is $ep.nodes[0], $ec1, "e3 removed, first child $ec1.name() again";

  # insert one element further before $ec2
  $ep.before( $ec2, $ec3, :offset(-1));
  is $ep.nodes[0], $ec3,
     "first child now $ec3.name() again, before with offset";

  $ec3.remove;
  $ep.after( $ec1, $ec3);
  is $ep.nodes[1], $ec3, "2nd child now $ec3.name(), after";

  $ec3.remove;
  $ep.after( $ec1, $ec3, :offset(2));
  is $ep.nodes[2], $ec3, "3rd child now $ec3.name(), after with offset";

  $ec3.remove;
  $ep.insert($ec3);
  is $ep.nodes[0], $ec3, "1st child $ec3.name(), insert";

  $ec3.remove;
  $ep.append($ec3);
  is $ep.nodes[2], $ec3, "3rd child $ec3.name(), append";
}

#--------------------------------------------------------------------------
subtest 'text, perl, str, append text', {

  my SemiXML::Element $ep .= new(:name<ep>);
  my SemiXML::Text $ect1 .= new(
    :text("hoeperde poep\nzat op de stoep"), :parent($ep)
  );

  is ~$ect1, "hoeperde poep\nzat op de stoep", 'text is the same as input';
  is $ect1.name, 'sxml:TNhoeperdepoepzatopdestoep', 'text node name';
  is $ect1.perl, 'sxml:TNhoeperdepoepzatopdestoep hoeperde poep\nzat op de stoep', 'perl output';

  is $ep.nodes[0], $ect1, "text child found";

  my SemiXML::Node $abc = $ep.append('abc');
  is $ep.nodes[1], $abc, 'abc is 2nd child, append';

  my SemiXML::Node $txt = $ep.append(:text<abc>);
  is $ep.nodes[2], $txt, 'txt is 3rd child, append';
  is $ep.nodes[2].name, 'sxml:TNabc', 'name is TNabc';

#  my SemiXML::Text $t = $ep«def ghi»;
#  $ep('def ghi');
#  is $ep.nodes[*-1], $t, 'returned text node found in nodes list';
#  is $ep.nodes[*-1].name, 'sxml:TNdefghi',
#     "text node $ep.nodes[*-1].name() appended";
}

#--------------------------------------------------------------------------
done-testing;
