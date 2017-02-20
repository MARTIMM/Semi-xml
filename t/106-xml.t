use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::Html::List
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
$|html [
  $|body [
    $!list.dir-list header=2,3 directory=t ref-attr=data_href id=ldir0001 []
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
#
mkdir('t/Grammars');
spurt( 't/Grammars/Debugging grammar rules.html', q:to/EOSXML/);
<html/>
EOSXML

spurt( 't/Grammars/Error messages.html', q:to/EOSXML/);
<html/>
EOSXML

my SemiXML::Sxml $x .= new;
$x.parse( :$filename, :$config);

my Str $xml-text = ~$x;
#note $xml-text;
spurt( 'a.html', $xml-text);

ok $xml-text ~~ m/'<ul id="ldir0001">'/, 'Id attribute on ul';
ok $xml-text ~~ m/'<li><h2>t</h2></li>'/, 'Top level h2';
ok $xml-text ~~ m/'<h3>Grammars</h3>'/, 'Second level Grammars';
ok $xml-text ~~ m/'<li><a href="" data_href="t/106-xml.t">xml</a></li>'/,
   'Ref to t/106-xml.t using ref-attr'
   ;

unlink $filename;
unlink 'a.html';
unlink 't/Grammars/Debugging grammar rules.html';
unlink 't/Grammars/Error messages.html';
rmdir 't/Grammars';

#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
