use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::File
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
---
output/fileext:                         html;

#library/file:                           .;
module/file:                            SxmlLib::File;
---
$html [
  $body [
    $!file.include type=include reference=t/D/d1.sxml [ ignored content ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
# Prepare directory and module to load
#
mkdir('t/D');
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
ok $xml-text !~~ m/'ignored content'/, 'Uncopied content';

unlink $filename;
unlink 't/D/d1.sxml';
rmdir('t/D');


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
