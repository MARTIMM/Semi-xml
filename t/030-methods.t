use v6;

use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# prepare directory and create module
my $dir = 't/T030';
my $mod = "$dir/m1.pm6";

mkdir($dir) unless $dir.IO ~~ :e;

spurt( $mod, q:to/EOMOD/);
  use v6;
  use Test;
  #use SemiXML::Sxml;
  use SxmlLib::SxmlHelper;
  use SemiXML::Text;
  use XML;

  class T030::m1 {

    # method 1 can be used at top of document
    method mth1 (
      XML::Element $parent, Hash $attrs, XML::Element :$content-body
      --> XML::Element
    ) {

      my XML::Element $p = append-element( $parent, 'p');
      std-attrs( $p, $attrs);
      ok $attrs<class>:!exists, 'class attribute removed';
      ok $attrs<id>:!exists, 'id attribute removed';
      ok $attrs<extra-attr>:exists, 'extra-attr attribute not removed';

      $parent;
    }

    # method 2 can not be used at top of document because it generates
    # more than one top level elements
    method mth2 (
      XML::Element $parent, Hash $attrs, XML::Element :$content-body
      --> XML::Element
    ) {

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

    method mth3 (
      XML::Element $parent, Hash $attrs, XML::Element :$content-body
      --> XML::Element
    ) {
      my XML::Element $ul = append-element( $parent, 'ul');
      $ul.set( 'class', ~$attrs<a>);

      #note "attributes: ", $attrs;
      #note "B should be a list or <> does not work: ", ~$attrs<b>;

      for @($attrs<b>)[*] -> $li-text {
        append-element( $ul, 'li', :text($li-text));
      }

      $parent;
    }
  }

  EOMOD

# setup the configuration
my Hash $config = {
  ML => {:mod1<T030::m1;t>}
}

#TODO spaces around brackets seems needed.
# setup the contents to be parsed with a substitution item in it
my Str $content = '$!mod1.mth1 id=method1 class=top-method extra-attr=nonsense [ ] ';

# instantiate parser and parse with contents and config
my SemiXML::Sxml $x .= new(:!trace);
my ParseResult $r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

my $xml = $x.get-xml-text;
#note "Xml: $xml";
like $xml, /'<p'/, "generated start of paragraph";
like $xml, /'class="top-method"'/, "found class attribute in '$xml'";


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
#note "XML: \n$xml";
like $xml, /'<?xml version="1.0" encoding="UTF-8"?>'/, 'found prelude';
like $xml, /'<x><p/><p>Added 0 xml nodes</p></x>'/, "generated content from mth2";


$content = '$x =a =!b [ $!mod1.mth2 [ $h [abc] $h[def]]]';
$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

$xml = $x.get-xml-text;
like $xml, /'<x a="1" b="0"><p/><p><h>abc</h><h>def</h>Added 2 xml nodes</p></x>'/,
           "generated: $xml";


$content = '$!mod1.mth3 a="v1 v2" b=<head1 head2>';
$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";
$xml = $x.get-xml-text;
#note $xml;
like $xml, /'<ul class="v1 v2"><li>head1</li><li>head2</li></ul>'/,
           "generated content from mth3";

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
