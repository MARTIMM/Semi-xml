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
output/fileext: mxml;
---
$top [
  $!SxmlCore.date []
  $!SxmlCore.date year=1957 month=6 day=26 []
  $!SxmlCore.date year=1957 day=26 []
  $!SxmlCore.date year=1957 month=6 []
  $!SxmlCore.date year=1957 []
  $*A []
  $*X [$!SxmlCore.date-time []]
  $*Y [$!SxmlCore.date-time iso=1 []]
  $*Z [$!SxmlCore.date-time iso=1 timezone=960 []]
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

$d = DateTime.now(:timezone(960)).Str;
#say "DT +T: $d";
ok $xml-text ~~ m:s/'<Z>' $d '</Z>'/, 'Check date and time in timezone';

is $x.get-option( :section('output'), :option('fileext')), 'mxml', 'Check fileext option';
is $x.get-option( :section('output'), :option('filepath')), '.', 'Check filepath option';
unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
