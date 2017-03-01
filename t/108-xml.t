use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of Core sxml methods
#     $!SxmlCore.comment [comment text]
#     $!SxmlCore.cdata [data text]
#     $!SxmlCore.pi [code text]
#-------------------------------------------------------------------------------
# Setup
my $dir = 't/D108';
mkdir $dir unless $dir.IO ~~ :e;
my $f1 = "$dir/test-file.sxml";

spurt( $f1, q:to/EOSX/);
$|html [
  $|body [
    $|h1 [Tests for comments etc]

    $!SxmlCore.comment [comment text]
    $!SxmlCore.comment [comment text $!SxmlCore.date []]
    $!SxmlCore.comment [comment text $|p [data in section] $|br []]

    $!SxmlCore.cdata [cdata text]
    $!SxmlCore.cdata [cdata text $!SxmlCore.date []]
    $!SxmlCore.cdata [cdata text $|p [data in section] $|br []]

    $!SxmlCore.pi target=perl6 [instruction text]
    $!SxmlCore.pi target=xml-stylesheet [ href="mystyle.css" type="text/css" ]

    $|h1 [End of tests]
  ]
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

my $d = Date.today();
ok $xml-text ~~ m/'<!--comment text-->'/, 'Check comments';
like $xml-text, / :s '<!--comment text' \d**4 '-' \d\d '-' \d\d '-->'/,
   'Check comments with other method';
ok $xml-text ~~ m/'<!--comment text<p>data in section</p><br/>-->'/,
   'Check comments with embedded tags';

ok $xml-text ~~ m/'<![CDATA[cdata text]]>'/, 'Check cdata';
like $xml-text, / :s '<![CDATA[cdata text' \d**4 '-' \d\d '-' \d\d ']]>'/,
   'Check cdata with other method';
ok $xml-text ~~ m/'<![CDATA[cdata text<p>data in section</p><br/>]]>'/,
   'Check cdata with embedded tags';

ok $xml-text ~~ m/'<?perl6 instruction text?>'/, 'Check pi data 1';
like $xml-text, /'<?xml-stylesheet href="mystyle.css" type="text/css"?>'/,
     'Check pi data 2';


#-------------------------------------------------------------------------------
# Cleanup

unlink $f1;
rmdir $dir;

done-testing();
exit(0);
