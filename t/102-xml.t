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

output/filename:                        t/some-file;    # Default current file
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


#say $xml-text;

unlink $filename;

# Write xml out to file. Filename explicitly set.
#
$filename ~~ s/\.sxml/.xml/;
$x.save(:$filename);
ok $filename.IO ~~ :e, "File $filename written";

unlink $filename;

$filename = 't/some-file.html';
$x.save;
ok $filename.IO ~~ :e, "File $filename written";

unlink $filename;

role pink {
  has Hash $!configuration = {
    output => {
      filename => 't/another',
      fileext => 'html'
    }
  };
}

$x does pink;

$filename = 't/another.html';
$x.save;
ok $filename.IO ~~ :!e, "File $filename not written";

$filename = 't/some-file.html';
ok $filename.IO ~~ :e, "File $filename written instead";

unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
