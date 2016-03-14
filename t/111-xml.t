use v6.c;
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

    $!m1.stats [ abc \$x [\] ]
    $!m1.stats [ def $x [ test 2 ] ]
    $!m1.stats [
      hij
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
  How 'bout this!
]
EOSXML

#-------------------------------------------------------------------------------
# Prepare directory and module to load
#
mkdir('t/M');
spurt( 't/M/m1.pm6', q:to/EOMOD/);
#use XML;
#use Semi-xml::Actions;
use Semi-xml;

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

  # Purpose is to pack content body's content in a p element
  #
  method stats ( XML::Element $parent,
                 Hash $attrs,
                 XML::Node :$content-body
               ) {

    my Semi-xml::Sxml $x .= new;
    my XML::Node $placeholder = $x.find-placeholder($parent);

    my $p = XML::Element.new(:name('p'));
    $parent.after( $placeholder, $p);

    while +$content-body.nodes {
      my $node = $content-body.nodes[0];
      $p.append($node);
    }
  }


  method statistics ( XML::Element $parent,
                      Hash $attrs,
                      XML::Node :$content-body
                    ) {

    # <table id="stat-id" class="red"></table>
    #
    my $table = XML::Element.new(
                  :name('table'),
                  :attribs( { class => 'red', id => 'stat-id'})
                );

    # Four records of 3 columns
    #
    for ^4 -> $count {
      # <tr></tr>
      #
      my $tr = XML::Element.new(:name('tr'));
      $table.append($tr);

      # <tr><td>data 1</td></tr>
      #
      my $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(Semi-xml::Text.new( :strip, :text('data 1')));

      # On 3rd row add text from attribute
      # <tr><td>data 1 set1</td></tr>
      #
      if $count == 2 {
        $td.append(Semi-xml::Text.new( :text(' ' ~ $attrs<data-weather>)));
      }

      # <tr><td>data 1</td><td>data 2 </td></tr>
      #
      $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(XML::Text.new(:text('data 2 ')));

      # <tr><td>data 1</td><td>data 2 $count$count$count$count</td></tr>
      #
      $td.append(Semi-xml::Text.new( :text("$count"))) for ^4;

      $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(XML::Text.new(:text('data 3')));
    }

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

ok $xml-text ~~ m/'<p>abc $x []</p>'/, 'Check text from $!stats';
ok $xml-text ~~ m/'<p>def<x>test 2</x></p>'/, 'Check complex text from $!stats';
ok $xml-text ~~ m/'<p>hij<h1>Intro</h1><p>How \'bout this!</p></p>'/,
   'Check complex text with nested call to $!file from $!stats';

ok $xml-text ~~ m/'class="red"'/, 'Check generated class = red';
ok $xml-text ~~ m/'id="stat-id"'/, 'Check generated id = stat-id';
ok $xml-text ~~ m/('<td>data 1 set1</td>'.*)**1/, "1 row with 'data 1 set1' td";
ok $xml-text ~~ m/('<td>data 1</td>'.*)**3/, "3 rows with 'data 1' td";
ok $xml-text ~~ m/('<td>data 2 ' \d**4 '</td>'.*)**4/, "4 rows with 'data 2 ' td";


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
