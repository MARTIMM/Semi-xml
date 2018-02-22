use v6;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::Html::List
#-------------------------------------------------------------------------------
# setup files
my $dir = 't/D106';
mkdir $dir unless $dir.IO ~~ :e;
my $f1 = "$dir/test-file.sxml";

my $gdir = "$dir/Grammars";
mkdir $gdir unless $gdir.IO ~~ :e;
my $g1 = "$gdir/Debugging grammar rules.html";
my $g2 = "$gdir/Error messages.html";

spurt( $f1, q:to/EOSX/);
$html [
  $head [
    $style «
      #ldir0001 ul {
        margin: 0 0 4px 0;
      }
      #ldir0001 h2 {
        margin: 0;
      }
      #ldir0001 h3 {
        margin: 0;
      }
      #ldir0001 ul, li {
        padding-left: 20px;
      }
    »
  ]
  $body [
    $!list.dir-list header=2,3 directory=t/D106 ref-attr=data-href id=ldir0001
                    []
  ]
]
EOSX

# setup config
my Hash $config = {
  ML => {
    in-fmt => {
      list => 'SxmlLib::Html::List'
    }
  },

  S => {
    test-file => {
      fileext => 'html'
    }
  },

  T => { :parse }
};

# some html files
spurt( $g1, q:to/EOSXML/);
  <html/>
  EOSXML

spurt( $g2, q:to/EOSXML/);
  <html/>
  EOSXML

#-------------------------------------------------------------------------------
# Parse
my SemiXML::Sxml $x .= new(:refine([<in-fmt out-fmt>]));
$x.parse( :filename($f1), :$config, :!trace, :!keep);
my Str $xml-text = ~$x;
#diag $xml-text;
"$dir/r,html".IO.spurt($xml-text);

ok $xml-text ~~ m/'id="ldir0001"'/, 'Id attribute on ul';
ok $xml-text ~~ m/'D106</h2><ul'/, 'Top level h2';
ok $xml-text ~~ m/'Grammars</h3>'/, 'Second level Grammars';
like $xml-text, /'href=""'/, 'empty href';
like $xml-text, /'data-href="t/D106/Grammars/Error messages.html"'/,
  'Error messages entry';

#-------------------------------------------------------------------------------
# Cleanup
done-testing();

unlink $f1;
unlink $g1;
unlink $g2;
unlink $g2;
unlink "$dir/r,html";
rmdir $gdir;
rmdir $dir;

exit(0);
