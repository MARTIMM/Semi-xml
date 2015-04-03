use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of Core sxml methods
#     $!SxmlCore.comment [comment text]
#     $!SxmlCore.cdata [data text]
#     $!SxmlCore.pi [code text]
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
---
output/fileext: html;
---
$html [
  $body [
    $h1 [Tests for comments etc]
    
    $!SxmlCore.comment [comment text]
    $!SxmlCore.comment [comment text $!SxmlCore.date []]
    $!SxmlCore.comment [comment text $p [data in section] $br []]

    $!SxmlCore.cdata [cdata text]
    $!SxmlCore.cdata [cdata text $!SxmlCore.date []]
    $!SxmlCore.cdata [cdata text $p [data in section] $br []]

    $!SxmlCore.pi [perl6 instruction text]

    $h1 [End of tests]
  ]
]
EOSX

#-------------------------------------------------------------------------------
# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
#say $xml-text;

my $d = Date.today();
ok $xml-text ~~ m/'<!--comment text-->'/, 'Check comments';
ok $xml-text ~~ m/'<!--comment text' \d**4\-\d\d\-\d\d '-->'/,
   'Check comments with other method';
ok $xml-text ~~ m/'<!--comment text<p>data in section</p><br/>-->'/,
   'Check comments with embedded tags';

ok $xml-text ~~ m/'<![CDATA[cdata text]]>'/, 'Check cdata';
ok $xml-text ~~ m/'<![CDATA[cdata text' \d**4\-\d\d\-\d\d']]>'/,
   'Check cdata with other method';
ok $xml-text ~~ m/'<![CDATA[cdata text<p>data in section</p><br/>]]>'/,
   'Check cdata with embedded tags';

ok $xml-text ~~ m/'<?perl6 instruction text?>'/, 'Check pi data';

unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
