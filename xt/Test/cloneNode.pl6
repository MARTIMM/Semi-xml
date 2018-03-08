#!/usr/bin/env perl6

use v6;
use XML;
use XML::XPath;

my $x = XML::XPath.new(:xml(q:to/EOXML/));

    <x>
      <y>abc</y>

      <t>
        <p />
      </t>
      <p />
    </x>
    EOXML

my $y = $x.find('//y', :to-list)[0];
note $y;

for $x.find('//p', :to-list) -> $p {
  note $p;

  my $yc = $y.cloneNode;
  $p.before($_.cloneNode) for $yc.nodes;
  $p.remove;
}

note ~$x.document;
