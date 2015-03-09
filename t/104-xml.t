use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Substitution of element names from symbol tables defined in
#   external modules.
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
#!bin/sxml2xml.pl6
#
---
output/fileext:                         html;

module/m1:                              t::M::m1;
---
$html [
  $head [
    $style type=text/css |[
        .green {
          color: \#0f0;
          background-color: \#f0f;
        }
    ]|
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

class t::M::m1 {
  has Hash $.symbols = {
    special-table => {
      tag-name => 'table',
      attributes => {
        class => 'big-table',
        id => 'new-table'
      }
    }
  };

  has Hash $.methods = {
    statistics => method ( Hash $attrs ) {
      my $table = XML::Element.new(
                    :name('table'),
                    :attribs( { class => 'red', id => 'stat-id'})
                  );
say "Self {self.perl}, {self.^name}";
#      my XML::Document $doc .= new(:root($table));

say "table {$table.perl}";

#say "doc {$doc.perl}";
      my $tr;
      my $td;
      for ^4 {
        $tr = XML::Element.new(:name('tr'));
say "\ntr: {$tr.perl}";
        $table.append($tr);
#        $tr.remove;
#say "removed";
#        $tr.parent = $table;
#say "parented";
#        $table.nodes.push($tr);
#say "pushed";
        $td = XML::Element.new(:name('td'));
        $tr.append($td);
        $td.append(XML::Text.new(:text('data 1')));

        $td = XML::Element.new(:name('td'));
        $tr.append($td);
        $td.append(XML::Text.new(:text('data 2')));

        $td = XML::Element.new(:name('td'));
        $tr.append($td);
        $td.append(XML::Text.new(:text('data 3')));
#`{{
}}
      }
say "returning";
say "Root";
      return $table;
    }
  };
}

EOMOD

#-------------------------------------------------------------------------------
# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
say $xml-text;

ok $xml-text ~~ m/\<table/, 'Check table name change';
ok $xml-text ~~ m/class\=\"big\-table\"/, 'Check class attribute';
ok $xml-text ~~ m/id\=\"new\-table\"/, 'Check id attribute';

unlink $filename;

unlink 't/M/m1.pm6';
rmdir('t/M');


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
