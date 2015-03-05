use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Write file with config prelude
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

output/filename:                        ../some-file    # Default current file
output/fileext:                         html;           # Default xml
---
$html [
  $body [
    $h1 [ Data from file ]
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


say $xml-text;

unlink $filename;

# Write xml out to file
#
$filename ~~ s/\.sxml/.xml/;
$x.save(:$filename);
ok $filename.IO ~~ :e, "File written";

unlink $filename;

#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
