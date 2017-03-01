use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Check of SemiLib::File
#-------------------------------------------------------------------------------
# Setup
my $dir = 't/D105';
mkdir $dir unless $dir.IO ~~ :e;

my $f1 = "$dir/test-file.sxml";
my $f2 = "$dir/d1.sxml";

spurt( $f1, q:to/EOSX/);
  $|html [
    $|body [
      $|h1 [First chapter]
      some text

      $!file.include type=include reference=t/D105/d1.sxml [ ignored content ]
    ]
  ]
  EOSX

#-------------------------------------------------------------------------------
# Prepare other sxml file to load into f1
spurt( $f2, q:to/EOSXML/);
  $|h1 [ Intro ]
  $|p [
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
my SemiXML::Sxml $x .= new;
$x.parse( :filename($f1), :$config);
my Str $xml-text = ~$x;
#note $xml-text;

ok $xml-text ~~ m/'<h1>Intro</h1>'/, "Check 'Intro' included";
ok $xml-text ~~ m/'<p>'/, 'Check p included';
ok $xml-text ~~ m/'How \'bout this!'/, 'Check p content';
ok $xml-text !~~ m/'ignored content'/, 'Uncopied content';

#-------------------------------------------------------------------------------
# Cleanup
done-testing();
unlink $f1;
unlink $f2;
rmdir $dir;

exit(0);
