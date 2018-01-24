use v6;
use Test;
use SemiXML::Helper;
use XML;
use XML::XPath;

#-------------------------------------------------------------------------------
my XML::XPath $xpath;
my XML::Element $x;
#-------------------------------------------------------------------------------
subtest 'append', {

  $x .= new(:name<x>);
  append-element( $x, 'y');

  my XML::XPath $xpath = get-xpath($x);
  ok $xpath.find( '/x/y', :to-list).elems, '/x/y found';

  $x .= new(:name<x>);
  append-element( $x, :text('hoeperde poep zat op de stoep'));
  $xpath = get-xpath($x);
  is $xpath.find('/x/text()').text,
     'hoeperde poep zat op de stoep', 'highly elevated text found';
}

#-------------------------------------------------------------------------------
sub get-xpath ( XML::Element $n --> XML::XPath ) {

  diag ~$n;

  # cannot create a document and load it using :document because Text is not
  # found properly by XPath.
  #
  # XML::Document $document .= new(~$n);
  # XML::XPath.new(:$document)
  XML::XPath.new(:xml(~$n))
}

#-------------------------------------------------------------------------------

done-testing;
