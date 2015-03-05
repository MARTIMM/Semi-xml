use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Setup
# Write file
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
-p-
options/doctype/show:                   1;
options/xml-prelude/show:               1;
options/xml-prelude/version:            1.0;
options/xml-prelude/encoding:           UTF-8;
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
ok $xml-text ~~ m/\<html\>/, 'Top level html found';
ok $xml-text !~~ m/\<head\>/, 'Head not found';
ok $xml-text ~~ ms/Data from file/, 'Section text found';

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
