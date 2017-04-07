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
$top [
  $!SxmlCore.date
  $!SxmlCore.date year=1957 month=6 day=26
  $!SxmlCore.date year=1957 day=26
  $!SxmlCore.date year=1957 month=6
  $!SxmlCore.date year=1957
  $**A
  $**X [ $!SxmlCore.date ]
  $**Y [ $!SxmlCore.date-time ]
  $**Z [ $!SxmlCore.date-time timezone=960 ]
  $**Z2 [ $!SxmlCore.date-time utc=1 iso=0 ]
]
EOSX

# '$**Z [$!SxmlCore.date-time iso=1 timezone=960]' produces an error
# 'Parse failure possible missing bracket at line 10-11, tag $**Z, body number 1

#-------------------------------------------------------------------------------
my Hash $config = {};
$config<S><test-file><fileext> = 'html';

#-------------------------------------------------------------------------------
# Parse
my SemiXML::Sxml $x .= new( :!trace, :merge);
$x.parse( :filename($f1), :$config);
my Date $d = Date.today;
my Str $xml-text = ~$x;
#note $xml-text;

my Str $dt = $d.Str;
my Str $dm = $d.month.fmt('%02d');
my Str $dd = $d.day.fmt('%02d');

diag "Some tests can go wrong on the split second at midnight";

ok $xml-text ~~ m:s/ '1957-06-26' /, 'Check specific date';
ok $xml-text ~~ m:s/ "1957-$dm-26" /, 'Check specific date on current month';
ok $xml-text ~~ m:s/ "1957-06-$dd" /, 'Check specific date on currnt day';
ok $xml-text ~~ m:s/ "1957-$dm-$dd" /, 'Check specific date on 1st day and month';
ok $xml-text ~~ m:s/ "<X> $dt\</X>" /, 'Check date of today';

#note 'Date: ', $d;
ok $xml-text ~~ m/ '<Y>'
                     $dt                                # year-month-day
                     'T' (\d\d ':')**2 \d\d             # hour:minute second
                     \.\d**6                            # millisec
                     ( '+' \d\d ':' \d\d | 'Z' ) '</Y>' # timezone offset
                                                        # On travis the local
                                                        # TZ is 'Z'
                   /, 'Check iso date, time and timezone';

ok $xml-text ~~ m/ '<Z>'
                     $dt                                # year-month-day
                     'T' (\d\d ':')**2 \d\d             # hour:minute second
                     \.\d**6                            # millisec
                     '+00:16'                           # timezone offset
                     '</Z>'
                   /, 'Check iso date, time and timezone of 960 sec';

like $xml-text, / '<Z2>'
                  $dt \s+                               # year-month-day
                  (\d\d ':')**2 \d\d                    # hour:minute second
                  'Z'                                   # zulu time
                  '</Z2>'
                /, 'Check utc date == timezone(0)';


#-------------------------------------------------------------------------------
# Cleanup
done-testing();

unlink $f1;
rmdir $dir;

exit(0);
