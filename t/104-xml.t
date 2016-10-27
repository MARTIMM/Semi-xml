use v6.c;
use Test;
use SemiXML;

#-------------------------------------------------------------------------------
# Testing;
#   Substitution of element names from symbol tables defined in
#   external modules and generating new tags and content.
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
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
    $h1 class=green [ Data from substitutes ]
    $.m1.special-table data-x=tst [
      $tr [ $th [ header ] ]
      $tr [ $td [ data ] ]
    ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {
  library => {
    m1 => 't'
  },
  
  module => {
    m1 => 'M::m1',
    file => 'SxmlLib::File'
  },
  
  output => {
    fileext => 'html',                  # Default xml
  }
}

#-------------------------------------------------------------------------------
# Prepare directory and module to load
#
mkdir('t/M');
spurt( 't/M/m1.pm6', q:to/EOMOD/);
#use XML;
#use SemiXML::Actions;
use SemiXML;

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
}

EOMOD

#-------------------------------------------------------------------------------
# Parse
#
my SemiXML::Sxml $x .= new;
$x.parse-file( :$filename, :$config);

my Str $xml-text = ~$x;
say $xml-text;

ok $xml-text ~~ m/'<table'**1/, 'Check substitution';
ok $xml-text ~~ m/class\=\"big\-table\"/, 'Check inserted class attribute';
ok $xml-text ~~ m/id\=\"new\-table\"/, 'Check inserted id attribute';

#`{{
ok $xml-text ~~ m/'<p>abc $x []</p>'/, 'Check text from $!stats';
ok $xml-text ~~ m/'<p>def<x>test 2</x></p>'/, 'Check complex text from $!stats';
ok $xml-text ~~ m/'<p>hij<h1>Intro</h1><p>How \'bout this!</p></p>'/,
   'Check complex text with nested call to $!file from $!stats';

ok $xml-text ~~ m/'class="red"'/, 'Check generated class = red';
ok $xml-text ~~ m/'id="stat-id"'/, 'Check generated id = stat-id';
ok $xml-text ~~ m/('<td>data 1 set1</td>'.*)**1/, "1 row with 'data 1 set1' td";
ok $xml-text ~~ m/('<td>data 1</td>'.*)**3/, "3 rows with 'data 1' td";
ok $xml-text ~~ m/('<td>data 2 ' \d**4 '</td>'.*)**4/, "4 rows with 'data 2 ' td";
}}

unlink $filename;
unlink 't/M/m1.pm6';
rmdir('t/M');

#unlink 't/D/d1.sxml';
#rmdir('t/D');

#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
