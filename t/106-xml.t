use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::Html::List
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
---
output/fileext:                         html;

module/file:                            SxmlLib::Html::List;
---
$html [
  $body [
    $!dir-list directory=t recursive=1 []
  ]
]
EOSX

#-------------------------------------------------------------------------------
# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
say $xml-text;

ok $xml-text ~~ m/'<h1>'/, 'Check h1 included';
ok $xml-text ~~ m/'<p>'/, 'Check p included';
ok $xml-text ~~ m/'How \'bout this!'/, 'Check p content';

unlink $filename;

#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
