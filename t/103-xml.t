use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Write file using default filename from program
#   Test |[ ]| contents to keep content as-is
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
#!bin/sxml2xml.pl6
#
---
options/doctype/show:                   1;              # Default 0

options/xml-prelude/show:               1;              # Default 0
options/xml-prelude/version:            1.1;            # Default 1.0
options/xml-prelude/encoding:           UTF-8;          # Default UTF-8

#output/filename:                        t/some-file;    # Default current file
output/fileext:                         html;           # Default xml
---
$html [
  $head [
    $style type=text/css [=
      .green {
        color: \#0f0;
        background-color: \#f0f;
      }
    ]
    $script [+
      var a_tags = $('a');
    ]
  ]

  $body [
    $h1 class=green [ Data from file ]
    $table [
      $tr [
        $th[ header ]
        $td[ data ]
      ]
    ]
  ]
]
EOSX

# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
ok $xml-text ~~ ms/'<?xml' 'version="1.1"' 'encoding="UTF-8"' '?>'/,
   'Xml prelude found';
ok $xml-text ~~ ms/'<!DOCTYPE' 'html>'/, 'Doctype found';

ok $xml-text ~~ m/
      '.green {
        color: #0f0;
        background-color: #f0f;
      }'
      /, 'Check for literal text in css';
ok $xml-text ~~ ms/ '<tr>' '<th>' /, 'Th after tr found';

ok $xml-text ~~ ms/var a_tags '=' "\$('a');"/, 'Check piece of javascript';

say $xml-text;

unlink $filename;

$filename = 't/103-xml.html';
$x.save;
ok $filename.IO ~~ :e, "File $filename written";

unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
