use v6.c;

use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# prepare directory and create module
my $dir = 't/T030';
my $mod = "$dir/m1.pm6";

mkdir($dir) unless $dir.IO ~~ :e;

spurt( $mod, q:to/EOMOD/);
  use v6.c;
  use SemiXML::Sxml;
  use SemiXML::Text;
  use XML;

  class T030::m1 {

    # method 1 can be used at top of document
    method mth1 (
      XML::Element $parent, Hash $attrs, XML::Element :$content-body
      --> XML::Element
    ) {
      # my XML::Element $p .= new(:name('p'));
      # $parent.append($p);
      append-element( $parent, 'p');
      $parent;
    }

    # method 2 can not be used at top of document because it generates
    # more than one top level elements
    method mth2 (
      XML::Element $parent, Hash $attrs, XML::Element :$content-body
      --> XML::Element
    ) {
      #my XML::Element $p .= new(:name('p'));
      #$parent.append($p);
      #$p .= new(:name('p'));
      #$parent.append($p);

      append-element( $parent, 'p');
      my XML::Element $p = append-element( $parent, 'p');

      # Eat from the end of the list and add just after the container element.
      # Somehow they get lost from the array when done otherwise.
      #
      my Int $nbr-nodes = $content-body.nodes.elems;
      $p.insert($_) for $content-body.nodes.reverse;
      $p.append(SemiXML::Text.new(:text("Added $nbr-nodes xml nodes")));

      $parent;
    }
  }

  EOMOD

# setup the configuration
my Hash $config = {
  library       => {:mod1<t>},
  module        => {:mod1<T030::m1>}
}

# setup the contents to be parsed with a substitution item in it
my Str $content = '$!mod1.mth1 [ ]';

# instantiate parser and parse with contents and config
my SemiXML::Sxml $x .= new(:trace);
my ParseResult $r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

my $xml = $x.get-xml-text;
is $xml, '<p/>', "generated $xml";



$content = '$!mod1.mth2 [ ]';
$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

$xml = $x.get-xml-text;
like $xml, /'<method-generated-too-many-nodes'/, "generated $xml";
like $xml, /'module="mod1"'/, "culprit module mod1";
like $xml, /'method="mth2"'/, "culprit method mth2";



$content = '$x [ $!mod1.mth2 [ ] ]';
$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

$xml = $x.get-xml-text;
is $xml, '<x><p/><p>Added 0 xml nodes</p></x>', "generated: $xml";



$content = '$x [ $!mod1.mth2 [ $h [abc] $h[def]]]';
$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

$xml = $x.get-xml-text;
say $xml;
is $xml, '<x><p/><p><h>abc</h><h>def</h>Added 2 xml nodes</p></x>', "generated: $xml";


#-------------------------------------------------------------------------------
# Cleanup
done-testing;
unlink $mod;
rmdir $dir;

exit(0);


=finish

like $xml, /'data-x="tst"'/, "Found data argument of table";
like $xml, /'id="new-table"'/, "Found id argument of table";
like $xml, /'id="special-id"'/, "Found id argument of td";



    $!m1.stats [ def $x [ test 2 ] ]
    $!m1.stats [
      hij
      $!file.include type=include reference=t/D/d1.sxml []
    ]

    $!m1.statistics data-weather=set1 [ data ]
    $p [ bla ]
