use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Setup
# Write file
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
$html [
  $body [
    $h1 [ Data from file ]
    $table [
      $tr [
        $th[header]
        $td[data]
      ]
    ]
  ]
]
EOSX



# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:file($filename));

my $xml-text = $x.Str;
ok $xml-text ~~ m/\<html\>/, 'Top level html found';
ok $xml-text !~~ m/\<head\>/, 'Head not found';
ok $xml-text ~~ ms/Data from file/, 'Section text found';

say $xml-text;

#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
