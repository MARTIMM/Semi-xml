use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of Core sxml methods
#     $!SxmlCore.date []
#     $!SxmlCore.date-time []
#-------------------------------------------------------------------------------
# Setup
my $dir = 't/D107';
mkdir $dir unless $dir.IO ~~ :e;
my $f1 = "$dir/test-file.sxml";


spurt( $f1, q:to/EOSX/);
$|top [
  $!SxmlCore.date []
  $!SxmlCore.date year=1957 month=6 day=26 []
  $!SxmlCore.date year=1957 day=26 []
  $!SxmlCore.date year=1957 month=6 []
  $!SxmlCore.date year=1957 []
  $**A []
  $**X [$!SxmlCore.date []]
  $**Y [$!SxmlCore.date-time iso=1 []]
  $**Z [$!SxmlCore.date-time iso=1 timezone=960 []]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {};
$config<output><fileext> = 'html';
$config<module><SxmlCore> = 'SxmlLib::SxmlCore';

#-------------------------------------------------------------------------------
# Parse
#
my SemiXML::Sxml $x .= new;
$x.parse( :filename($f1), :$config);
my Str $xml-text = ~$x;
#note $xml-text;

diag "Some tests can go wrong on the split second at midnight";
my $d = Date.today().Str;
ok $xml-text ~~ m:s/ '1957-06-26' /, 'Check specific date';
ok $xml-text ~~ m:s/ '1957-01-26' /, 'Check specific date on 1st month';
ok $xml-text ~~ m:s/ '1957-06-01' /, 'Check specific date on 1st day';
ok $xml-text ~~ m:s/ '1957-01-01' /, 'Check specific date on 1st day and month';
ok $xml-text ~~ m:s/ '<X>' $d '</X>' /, 'Check date of today';

#note 'Date: ', $d;
ok $xml-text ~~ m/ '<Y>'
                     $d                                 # year-month-day
                     'T' (\d\d ':')**2 \d\d             # hour:minute second
                     \.\d**6                            # millisec
                     ( '+' \d\d ':' \d\d | 'Z' ) '</Y>' # timezone offset
                                                        # On travis the local
                                                        # TZ is 'Z'
                   /,
  'Check iso date, time and timezone';

ok $xml-text ~~ m/ '<Z>'
                     $d                                 # year-month-day
                     'T' (\d\d ':')**2 \d\d             # hour:minute second
                     \.\d**6                            # millisec
                     '+00:16</Z>'                       # timezone offset
                   /,
  'Check iso date, time and timezone of 960 sec';



#-------------------------------------------------------------------------------
# Cleanup
done-testing();

unlink $f1;
rmdir $dir;

exit(0);
