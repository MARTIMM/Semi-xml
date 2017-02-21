use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::Html::List
#-------------------------------------------------------------------------------
# Setup
my $dir = 't/D106';
mkdir $dir unless $dir.IO ~~ :e;
my $f1 = "$dir/test-file.sxml";

my $gdir = "$dir/Grammars";
mkdir $gdir unless $gdir.IO ~~ :e;
my $g1 = "$gdir/Debugging grammar rules.html";
my $g2 = "$gdir/Error messages.html";


spurt( $f1, q:to/EOSX/);
$|html [
  $|body [
    $!list.dir-list header=2,3 directory=t/D106 ref-attr=data_href id=ldir0001 []
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {
  module => {
    list => 'SxmlLib::Html::List'
  },

  output => {
    fileext => 'html'
  }
};

#-------------------------------------------------------------------------------
# Parse
spurt( $g1, q:to/EOSXML/);
  <html/>
  EOSXML

spurt( $g2, q:to/EOSXML/);
  <html/>
  EOSXML

my SemiXML::Sxml $x .= new;
$x.parse( :filename($f1), :$config);
my Str $xml-text = ~$x;
#note $xml-text;

# To check html by viewing, dumpit
spurt( "$dir/r.html", $xml-text);

ok $xml-text ~~ m/'<ul id="ldir0001">'/, 'Id attribute on ul';
ok $xml-text ~~ m/'<li><h2>D106</h2></li>'/, 'Top level h2';
ok $xml-text ~~ m/'<h3>Grammars</h3>'/, 'Second level Grammars';
ok $xml-text ~~ m/'<li><a href="" data_href="t/D106/Grammars/Error messages.html">Error messages</a></li>'/,
   'Ref to t/D106/Grammars/Error messages.html using ref-attr'
   ;

#-------------------------------------------------------------------------------
# Cleanup
done-testing();

unlink $f1;
unlink $g1;
unlink $g2;
unlink "$dir/r.html";
rmdir $gdir;
rmdir $dir;

exit(0);
