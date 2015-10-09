use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Substitution of element names from symbol tables defined in
#   external modules and generating new tags and content.
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
#!bin/sxml2xml.pl6
#
---
output/fileext:                         html;

library/m1:                             t;
module/m1:                              M::m1;
module/file:                            SxmlLib::File;
---
$html [
  $head [
    $style type=text/css [=
        .green {
          color: \#0f0;
          background-color: \#f0f;
        }
    ]
  ]

  $body [
    $h1 class=green [ Data from file ]
    $.m1.special-table data-x=tst [
      $tr [ $th [ header ] ]
      $tr [ $td [ data ] ]
    ]

    $!m1.stats [ bla die bla \$x [\] ]
    $!m1.stats [ bla die bla $x [ test 2 ] ]
    $!m1.stats [
      bla die bla
      $!file.include type=include reference=t/D/d1.sxml []
    ]
    
    $!m1.statistics data-weather=set1 [ data ]
    $p [ bla ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
# Prepare directory and module to load
#
mkdir('t/D');
spurt( 't/D/d1.sxml', q:to/EOSXML/);
$h1 [ Intro ]
$p [
  How 'bout this!'
]
EOSXML

#-------------------------------------------------------------------------------
# Prepare directory and module to load
#
mkdir('t/M');
spurt( 't/M/m1.pm6', q:to/EOMOD/);
use XML;
use Semi-xml::Actions;

class M::m1 {
  has Hash $.symbols = {
    special-table => {
      tag-name => 'table',
      attributes => {
        class => 'big-table',
        id => 'new-table'
      }
    }
  };

  method stats ( XML::Element $parent,
                 Hash $attrs,
                 XML::Node :$content-body
               ) {
#say "CB 0: {$parent.parent.name}";
#say "CB 0: {$parent.^name}, {$parent.name}";
#say "CB 0: {@content-body.^name}, {@content-body.name}";

    my $p = XML::Element.new(:name('p'));
    $parent.append($p);
    $p.append($_) for $content-body.nodes;
    $content-body.remove;
  }


  method statistics ( XML::Element $parent,
                      Hash $attrs,
                      XML::Node :$content-body
                    ) {
#say "CB 1: {$parent.parent.name}";
#say "CB 1: {$parent.^name}, {$parent.name}";
#say "CB 1: {@content-body.^name}, {@content-body.name}";

    my $table = XML::Element.new(
                  :name('table'),
                  :attribs( { class => 'red', id => 'stat-id'})
                );

    for ^4 {
      my $tr = XML::Element.new(:name('tr'));
      $table.append($tr);
      my $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(Semi-xml::Text.new( :strip, :text('data 1')));
      
      if $_ == 2 {
        $td.append(Semi-xml::Text.new( :text(' ' ~ $attrs<data-weather>)));
      }

      $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(XML::Text.new(:text('data 2 ')));

      # We do this 4 times but only the first td element will have the data
      # because it wil reparent everytime. To do it properly, clone the element
      # first.
      #
      $td.append($_) for $content-body.nodes;

      $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(XML::Text.new(:text('data 3')));
    }

    $content-body.remove;
    $parent.append($table);
  }
}

EOMOD

#-------------------------------------------------------------------------------
# Parse
#
my Semi-xml::Sxml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
#say $xml-text;

ok $xml-text ~~ m/('<table'.*)**2/, 'Check subst and gen of $.special-table and $!statistics';
ok $xml-text ~~ m/class\=\"big\-table\"/, 'Check inserted class attribute';
ok $xml-text ~~ m/id\=\"new\-table\"/, 'Check inserted id attribute';

ok $xml-text ~~ m/'<p>bla die bla $x []</p>'/, 'Check text from $!stats';
ok $xml-text ~~ m/'<p>bla die bla<x>test 2</x></p>'/, 'Check complex text from $!stats';
ok $xml-text ~~ m/'<p>bla die bla<h1>Intro</h1><p>How \'bout this!\'</p></p>'/,
   'Check complex text with nested call to $!file from $!stats';

ok $xml-text ~~ m/'class="red"'/, 'Check generated class = red';
ok $xml-text ~~ m/'id="stat-id"'/, 'Check generated id = stat-id';
ok $xml-text ~~ m/('<td>data 1 set1</td>'.*)**1/, "Check 1 inserted 'data 1 set1' td";
ok $xml-text ~~ m/('<td>data 1</td>'.*)**3/, "Check 3 inserted 'data 1' td";
ok $xml-text ~~ m/('<td>data 2 </td>'.*)**3/, "Check 3 no inserted 'data 2 ' content td";
ok $xml-text ~~ m/('<td>data 2 data</td>'.*)**1/, "Check 1 inserted 'data 2 data' content td";

unlink $filename;
unlink 't/M/m1.pm6';
rmdir('t/M');

unlink 't/D/d1.sxml';
rmdir('t/D');

#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
