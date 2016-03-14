use v6.c;
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
output/fileext: html;
---
$html [
  $body [
    $p1 [ x y $!SxmlCore.date [] ]
    $p2 z=txt [ $!SxmlCore.date-time [] ]
    $p3 [ $!SxmlCore.date [] ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
# Parse
#
my Semi-xml::Sxml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
#say $xml-text;

diag "This test can go wrong on the split second at midnight";
my $d = Date.today();
ok $xml-text ~~ m:s/'<p1>x y ' $d'</p1>'/, 'Check generated date';

ok $xml-text ~~ m:s/ '<p2 z="txt">'
                     $d                                 # year-month-day
                     (\d\d ':')**2 \d\d                 # hour:minute second
                     \.\d**6                            # millisec
                     '+' \d\d ':' \d\d '</p2>'          # timezone offset
                   /,
  'Check generated date and time';

is $x.get-option( :section('output'), :option('fileext')), 'html', 'Check fileext option';
is $x.get-option( :section('output'), :option('filepath')), '.', 'Check filepath option';
unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
