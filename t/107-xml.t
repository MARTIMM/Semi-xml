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
  $*X [$!SxmlCore.date []]
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

diag "Some tests can go wrong on the split second at midnight";
my $d = Date.today().Str;
ok $xml-text ~~ m:s/ '1957-06-26' /, 'Check specific date';
ok $xml-text ~~ m:s/ '1957-01-26' /, 'Check specific date on 1st month';
ok $xml-text ~~ m:s/ '1957-06-01' /, 'Check specific date on 1st day';
ok $xml-text ~~ m:s/ '1957-01-01' /, 'Check specific date on 1st day and month';

ok $xml-text ~~ m:s/ '<X>' $d '</X>' /, 'Check date of today';

#say 'Date: ', $d;
ok $xml-text ~~ m/ '<Y>'
                     $d                                 # year-month-day
                     'T' (\d\d ':')**2 \d\d             # hour:minute second
                     \.\d**6                            # millisec
                     '+' \d\d ':' \d\d '</Y>'           # timezone offset
                   /,
  'Check iso date, time and timezone';

ok $xml-text ~~ m/ '<Z>'
                     $d                                 # year-month-day
                     'T' (\d\d ':')**2 \d\d             # hour:minute second
                     \.\d**6                            # millisec
                     '+00:16</Z>'                       # timezone offset
                   /,
  'Check iso date, time and timezone of 960 sec';

is $x.get-option( :section('output'), :option('fileext')), 'mxml', 'Check fileext option';
is $x.get-option( :section('output'), :option('filepath')), '.', 'Check filepath option';
unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
