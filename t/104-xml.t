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
    $.special-table data-x=tst [
      $tr [
        $th[ header ]
        $td[ data ]
      ]
    ]

    $!statistics data-weather=set1 []
    $p [ bla ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
# Prepare directory and module to load
#
ok mkdir('t/M'), 'Directory M created';
spurt( 't/M/m1.pm6', q:to/EOMOD/);
use XML;

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

  method statistics ( XML::Element $parent, Hash $attrs ) {
    my $table = XML::Element.new(
                  :name('table'),
                  :attribs( { class => 'red', id => 'stat-id'})
                );

    for ^4 {
      my $tr = XML::Element.new(:name('tr'));
      $table.append($tr);
      my $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(XML::Text.new(:text('data 1')));

      $td = XML::Element.new(:name('td'));
      $tr.append($td);
      $td.append(XML::Text.new(:text('data 2')));

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
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
#say $xml-text;

ok $xml-text ~~ m/('<table'.*)**2/, 'Check subst and gen of $.special-table and $!statistics';
ok $xml-text ~~ m/class\=\"big\-table\"/, 'Check inserted class attribute';
ok $xml-text ~~ m/id\=\"new\-table\"/, 'Check inserted id attribute';

ok $xml-text ~~ m/'class="red"'/, 'Check generated class = red';
ok $xml-text ~~ m/'id="stat-id"'/, 'Check generated id = stat-id';
ok $xml-text ~~ m/('<td>data 1</td>'.*)**4/, "Check 4 inserted 'data 1' td";

unlink $filename;

unlink 't/M/m1.pm6';
rmdir('t/M');


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
