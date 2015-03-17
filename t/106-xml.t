use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::Html::List
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
---
output/fileext:                         html;

module/list:                            SxmlLib::Html::List;
---
$html [
  $body [
    $!list.dir-list header=2,3 directory=t id=ldir0001 []
  ]
]
EOSX

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

my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
#say $xml-text;

ok $xml-text ~~ m/'<ul id="ldir0001">'/, 'Id attribute on ul';
ok $xml-text ~~ m/'<li><h2>t</h2></li>'/, 'Top level h2';
ok $xml-text ~~ m/'<h3>Grammars</h3>'/, 'Second level Grammars';

unlink $filename;

unlink 't/Grammars/Debugging grammar rules.html';
unlink 't/Grammars/Error messages.html';
rmdir 't/Grammars';

#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
