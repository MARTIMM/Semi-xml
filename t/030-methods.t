use v6;

#use XML;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# prepare directory and create module
my $dir = 't/T030';
my $mod = "$dir/m1.pm6";

mkdir($dir) unless $dir.IO ~~ :e;

spurt( $mod, q:to/EOMOD/);
  use v6;
  use SemiXML::Element;

  class T030::m1 {

    # method 1 can be used at top of document
    method mth1 ( SemiXML::Element $m ) {

      my SemiXML::Element $p .= new(:name<p>);
      $p.cp-std-attrs($m.attributes);
      $m.before($p);
    }

    # method 2 can not be used at top of document because it generates
    # more than one top level elements
    method mth2 ( SemiXML::Element $m ) {

      my SemiXML::Element $p .= new(:name<p>);
      $m.before($p);
      $p .= new(:name<p>);
      $m.before($p);

      my Int $nbr-nodes = $m.nodes.elems;
      $p.insert($_) for $m.nodes.reverse;
      $p.append(:text("Added $nbr-nodes xml nodes"));
    }

    method mth3 ( SemiXML::Element $m ) {
      my SemiXML::Element $ul .= new(:name<ul>);
      $ul.attributes<class> = ~$m.attributes<a>;

      for @($m.attributes<b>)[*] -> $li-text {
        $ul.append( 'li', :text($li-text));
      }

      $m.before($ul);
    }
  }

  EOMOD

# setup the configuration
my Hash $config = {
  ML => {:mod1<T030::m1;t>},
  T => {:!parse, :!parse-result},
}

# setup the contents to be parsed with a substitution item in it
my Str $content =
  '$!mod1.mth1 id=method1 class=top-method extra-attr=nonsense [ ]';

# instantiate parser and parse with contents and config
my SemiXML::Sxml $x .= new;
$x.parse( :$config, :$content);

my $xml = $x.get-xml-text;
#diag "Xml: $xml";

like $xml, /'<p'/, "generated start of paragraph";
like $xml, /'class="top-method"'/, "found class attribute in '$xml'";

throws-like {
  $content = '$!mod1.mth2 [ ]';
  $x.parse( :$config, :$content);

  # exception is thrown when result is retrieved
  $x.Str;
}, X::SemiXML, 'Too many nodes on top',
:message(/:s Too many nodes on top level/);

lives-ok {
  $content = '$!mod1.mth2 [ ]';
  $x.parse( :$config, :$content, :frag);
}, "Fragment generated";


$content = '$x [ $!mod1.mth2 [ ] ]';
$x.parse( :$config, :$content);

$xml = $x.get-xml-text;
#diag "XML: $xml";
like $xml, /'<?xml version="1.0" encoding="UTF-8"?>'/, 'found prelude';
like $xml, /'<x><p></p><p>Added 1 xml nodes</p></x>'/,
     "mth2 sees at least 1 space in its content";

$content = '$x =a =!b [ $!mod1.mth2 [$h [abc] $h[def]]]';
$x.parse( :$config, :$content, :!trace);

$xml = $x.get-xml-text;
like $xml, /:s '<x a="1" b="0">'
             '<p></p>'
             '<p>' '<h>abc</h>' '<h>def</h>'
             'Added 3 xml nodes'
             '</p>'
             '</x>'
           /, "generated 3 nodes";


$content = '$!mod1.mth3 a="v1 v2" b=<head1 head2> []';
$x.parse( :$config, :$content);
$xml = $x.get-xml-text;
#diag $xml;
like $xml, /'<ul class="v1 v2"><li>head1</li><li>head2</li></ul>'/,
           "generated content from mth3";

#-------------------------------------------------------------------------------
# Cleanup
done-testing;
unlink $mod;
rmdir $dir;


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
