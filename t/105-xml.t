use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of Semi-xml::Lib::File
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
---
output/fileext:                         html;

#library/file:                           .;
module/file:                            Sxml::Lib::File;
---
$html [
  $body [
    $!include type=include reference=t/D/d1.sxml []
  ]
]
EOSX

#-------------------------------------------------------------------------------
# Prepare directory and module to load
#
ok mkdir('t/D'), 'Directory D created';
spurt( 't/D/d1.sxml', q:to/EOSXML/);
$h1 [ Intro ]
$p [
  How 'bout this!
]
EOSXML

#-------------------------------------------------------------------------------
# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
#say $xml-text;

ok $xml-text ~~ m/'<h1>'/, 'Check h1 included';
ok $xml-text ~~ m/'<p>'/, 'Check p included';
ok $xml-text ~~ m/'How \'bout this!'/, 'Check p content';

unlink $filename;
unlink 't/D/d1.sxml';
rmdir('t/D');


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
