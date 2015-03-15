use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of Core sxml methods
#     $!SxmlCore.date []
#     $!SxmlCore.date-time []
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
---
output/fileext:                         html;
---
$html [
  $body [
    $p1 [ $!SxmlCore.date [] ]
    $p2 [ $!SxmlCore.date-time [] ]
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

my $d = Date.today();
ok $xml-text ~~ m/'<p1>' $d '</p1>'/, 'Check generated date';

ok $xml-text ~~ m/'<p2>' $d 'T' (\d\d ':')**2 \d\d '+' \d**4 '</p2>'/,
  'Check generated date and time';

unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
