use v6;
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
  $A
  $X [ $!SxmlCore.date ]
  $Y [ $!SxmlCore.date-time ]
  $Z [ $!SxmlCore.date-time timezone=960 ]
  $Z2 [ $!SxmlCore.date-time utc=1 iso=0 ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {

  S => {
    test-file => { :fileext<html> }
  }
};

#-------------------------------------------------------------------------------
# Parse
my SemiXML::Sxml $x .= new;
$x.parse( :filename($f1), :$config, :!trace, :!raw, :!keep);
my Date $d = Date.today;
my Str $xml-text = ~$x;
#diag $xml-text;

my Str $dt = $d.Str;
my Str $dm = $d.month.fmt('%02d');
my Str $dd = $d.day.fmt('%02d');

diag "Some tests can go wrong on the split second at midnight";
#diag "dm: $dm";
#diag "dd: $dd";

like $xml-text, / '1957-06-26' /, 'Check specific date';
like $xml-text, / "1957-$dm-26" /, 'Check specific date on current month';
like $xml-text, / "1957-06-$dd" /, 'Check specific date on current day';
like $xml-text, / "1957-$dm-$dd" /,
   'Check specific date on 1st day and month';
like $xml-text, /:s '<X>' $dt '</X>' /, 'Check date of today';

#diag "dt: $dt";
like $xml-text, / '<Y>'
                    $dt                                # year-month-day
                    T (\d\d ':')**2 \d\d               # hour:minute second
                    \. \d**6                           # millisec
                    [ '+' \d\d ':' \d\d || Z ]         # timezone offset
                    '</Y>'                             # On travis the local
                                                       # TZ is 'Z'
                /, 'Check iso date, time and timezone';

like $xml-text, / '<Z>'
                  $dt                                  # year-month-day
                  'T' (\d\d ':')**2 \d\d               # hour:minute second
                  \. \d**6                             # millisec
                  '+00:16'                             # timezone offset
                  '</Z>'
                /, 'Check iso date, time and timezone of 960 sec';

like $xml-text, / '<Z2>'
                  $dt \s                               # year-month-day
                  (\d\d ':')**2 \d\d                   # hour:minute second
                  'Z'                                  # zulu time
                  '</Z2>'
                /, 'Check utc date == timezone(0)';


#-------------------------------------------------------------------------------
# Cleanup
done-testing();

unlink $f1;
rmdir $dir;
