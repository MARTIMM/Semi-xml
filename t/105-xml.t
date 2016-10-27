use v6.c;
use Test;
use SemiXML;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::File
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
$html [
  $body [
    $h1 [First chapter]
    some text

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
my Hash $config = {
  module => {
    file => 'SxmlLib::File'
  },
  
  output => {
    fileext => 'html'
  }
};

#-------------------------------------------------------------------------------
# Parse
#
my SemiXML::Sxml $x .= new;
$x.parse-file( :$filename, :$config);

my Str $xml-text = ~$x;
#say "\nXml: $xml-text";

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
done-testing();
exit(0);
