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

my $d = Date.today().Str;
ok $xml-text ~~ m:s/ $d /, 'Check date of today';

ok $xml-text ~~ m:s/ '1957-06-26' /, 'Check specific date';
ok $xml-text ~~ m:s/ '1957-01-26' /, 'Check specific date on 1st month';
ok $xml-text ~~ m:s/ '1957-06-01' /, 'Check specific date on 1st day';
ok $xml-text ~~ m:s/ '1957-01-01' /, 'Check specific date on 1st day and month';

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
