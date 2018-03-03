use v6;
use Test;

use SemiXML;
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
  is $ect1.name, 'sxml:TN-hoeperdepo-001', 'text node name';
  is $ect1.perl, "sxml:TN-hoeperdepo-001 (¬i t ¬k ¬s | )" ~
     " 'hoeperde poep\\nzat op de stoep ...'", 'perl output';

  is $ep.nodes[0], $ect1, "text child found";

  my SemiXML::Node $abc = $ep.append('abc');
  is $ep.nodes[1], $abc, 'abc is 2nd child, append';

  my SemiXML::Node $txt = $ep.append(:text<abc>);
  is $ep.nodes[2], $txt, 'txt is 3rd child, append';
  is $ep.nodes[2].name, 'sxml:TN-abc-002', "name is '{$ep.nodes[2].name}'";

#  my SemiXML::Text $t = $ep«def ghi»;
#  $ep('def ghi');
#  is $ep.nodes[*-1], $t, 'returned text node found in nodes list';
#  is $ep.nodes[*-1].name, 'sxml:TNdefghi',
#     "text node $ep.nodes[*-1].name() appended";
}

#--------------------------------------------------------------------------
subtest 'search simple', {

  =begin comment
  structure created
  +-sxml:fragment
    +-ep
      +-e1
      +-e2
      | +-e4
      | | +-e1
      | +-e4
      +-e3
  =end comment

  my SemiXML::Element $root .= new(
      :name<sxml:fragment>,
      :attributes({'xmlns:sxml' => 'https://github.com/MARTIMM/Semi-xml'})
    );

  my SemiXML::Element $ep = $root.append('ep');
  my SemiXML::Element $e1 = $ep.append('e1');
  my SemiXML::Element $e2 = $ep.append('e2');
  my $e4 = $e2.append('e4');
  $e4.append('e1');
  $e2.append('e4');
  $ep.append('e3');

  my Array $r = $e2.search( SemiXML::SCChild, 'e4');
  is $r.elems, 2, 'two e4 elements found on e2';

  $r = $ep.search( SemiXML::SCChild, '*');
  is $r.elems, 3, 'three elements found with * on ep';

  $r = $e2.search( SemiXML::SCChild, 'e2');
  is $r.elems, 0, 'no e2 element on e2';

  $r = $e2.search( SemiXML::SCParent, 'e2');
  is $r.elems, 1, 'one e2 element on parent of e2';

  $r = $e2.search( SemiXML::SCChild, 'ep');
  is $r.elems, 0, 'ep element not found';

  $r = $e2.search( SemiXML::SCRoot, 'ep');
  is $r.elems, 1, 'one ep element found from root';
}

#--------------------------------------------------------------------------
subtest 'search complex 1', {

  =begin comment
  structure created
  +-sxml:fragment
    +-ep
      +-e1
      | +-e5
      | +-e2
      +-e2
      | +-e4
      | | +-e1
      | +-e4
      | +-e4
      +-e3
  =end comment

  my SemiXML::Element $root .= new(
      :name<sxml:fragment>,
      :attributes({'xmlns:sxml' => 'https://github.com/MARTIMM/Semi-xml'})
    );

  my SemiXML::Element $ep = $root.append('ep');
  my SemiXML::Element $e1 = $ep.append('e1');
  $e1.append('e5');
  $e1.append('e2');
  my SemiXML::Element $e2 = $ep.append('e2');
  my $e4 = $e2.append('e4');
  $e4.append('e1');
  $e2.append('e4');
  $e2.append('e4');
  $ep.append('e3');

  my Array $r = $e2.search( [ SemiXML::SCChild, 'e4']);
  is $r.elems, 3, 'three e4 elements found on e2';

  $r = $e2.search( [ SemiXML::SCRoot, 'e5']);
  is $r.elems, 0, 'no e5 elements found on root';

  $r = $e2.search( [ SemiXML::SCRootDesc, 'e5']);
  is $r.elems, 1, 'one e5 element found below root';

  $r = $ep.search( [ SemiXML::SCDesc, 'e2']);
  is $r.elems, 2, 'two e2 elements found below ep';

  # .//e2/*
  $r = $ep.search( [
      SemiXML::SCDesc,      'e2',
      SemiXML::SCChild,     '*'
    ]
  );
  is $r.elems, 3, '3 elements .//e2/* on ep';

  $r = $e4.search( [
      SemiXML::SCRootDesc,  'e2',
      SemiXML::SCChild,     '*'
    ]
  );
  is $r.elems, 3, '3 elements //e2/* on e4';

  $r = $e4.search( [
      SemiXML::SCRoot,      'ep',
      SemiXML::SCChild,     'e1',
      SemiXML::SCChild,     'e5'
    ]
  );
  is $r.elems, 1, '1 element /ep/e1/e5 on e4';
  is $r[0].name, 'e5', 'name of node is e5';

  $r = $e4.search( [
      SemiXML::SCRoot,      '*',
      SemiXML::SCChild,     'e2',
    ]
  );
  is $r.elems, 1, '1 element /*/e2 on e4';
}

#--------------------------------------------------------------------------
subtest 'search complex 2', {

  =begin comment
  structure created
  +-sxml:fragment
    +-ep
      +-e1
      | +-e10
      | +-t1
      +-e2
      | +-t2
      +-e3
  =end comment

  my SemiXML::Element $root .= new(
      :name<sxml:fragment>,
      :attributes({'xmlns:sxml' => 'https://github.com/MARTIMM/Semi-xml'})
    );

  my SemiXML::Element $ep = $root.append('ep');
  my SemiXML::Element $e1 = $ep.append( 'e1', :text('text 1'));
  $e1.append('e10');
  my SemiXML::Element $e2 = $ep.append( 'e2', :text('text 2'));
  $ep.append('e3');

  my Array $r = $e2.search( [ SemiXML::SCChild, 'text()']);
  is $r.elems, 1, '1 text element ./text() on e2';
  is $r[0].text, 'text 2', 'text is correct';
  is $r[0].name, 'sxml:TN-text2-004', "name is '$r[0].name()'";

  $r = $e2.search( [ SemiXML::SCRootDesc, 'text()']);
  is $r.elems, 2, '2 text elements //text() on e2';

  $r = $e2.search( [ SemiXML::SCParentDesc, 'text()']);
  is $r.elems, 2, '2 text elements ..//text() on e2';
}

#--------------------------------------------------------------------------
subtest 'search complex 3', {

  =begin comment
  structure created
  +-sxml:fragment
    +-ep
      +-e1 a=v1
      | +-e10 a=v2
      | +-t1
      +-e2 a=v1 b=v4
      | +-t2
      +-e3
  =end comment

  my SemiXML::Element $root .= new(
      :name<sxml:fragment>,
      :attributes({'xmlns:sxml' => 'https://github.com/MARTIMM/Semi-xml'})
    );

  my SemiXML::Element $ep = $root.append('ep');
  my SemiXML::Element $e1 = $ep.append(
    'e1', :text('text 1'), :attributes({:a<v1>})
  );
  $e1.append( 'e10', :attributes({:a<v2>}));
  my SemiXML::Element $e2 = $ep.append(
    'e2', :text('text 2'), :attributes({ :a<v1>, :b<v4>})
  );
  $ep.append('e3');

  #diag "Xml: " ~ $ep.xml;

  my Array $r = $e1.search( [ SemiXML::SCChild, '*']);
  is $r.elems, 1, '1 element ./* on e1';

  #diag "R: " ~ $r.perl;

  $r = $e1.search( [ SemiXML::SCChild, 'node()']);
  is $r.elems, 2, '2 elements ./node() on e1';

  $r = $e2.search( [ SemiXML::SCAttr, '@*']);
  is $r.elems, 1, '1 node for ./@* on e2';
  is $r[0].attributes<a>, 'v1', 'attribute a = v1';
  is $r[0].attributes<b>, 'v4', 'attribute b = v4';
  is $r[0].name, 'e2', 'Name of attributes node is e2';

  $r = $e1.search( [ SemiXML::SCAttr, '@a']);
  is $r.elems, 1, '1 node for ./@a on e1';
  is $r[0].attributes<a>, 'v1', 'attribute a = v1';
  is $r[0].name, 'e1', 'Name of attributes node is e1';

  $r = $e1.search( [ SemiXML::SCRootDesc, '*', SemiXML::SCAttr, '@a']);
  is $r.elems, 3, '3 nodes for //*/@a';
  is $r[0].name, 'e1', 'Name of attributes node is e1';
  is $r[1].name, 'e2', 'Name of attributes node is e2';
  is $r[2].name, 'e10', 'Name of attributes node is e10';

  $r = $e1.search( [ SemiXML::SCRootDesc, '*', SemiXML::SCAttr, '@a=v1']);
  is $r.elems, 2, '2 nodes for //*/@a=v1';
}

#--------------------------------------------------------------------------
done-testing;
