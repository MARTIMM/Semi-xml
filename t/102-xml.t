use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Write file with config prelude
#-------------------------------------------------------------------------------
# Setup
#
my $dir = 't/D102';
mkdir $dir unless $dir.IO ~~ :e;

my $filename = "$dir/test-file.sxml";

my $f1 = $filename;
$f1 ~~ s/ \.sxml /.html/;
my $f1bn = $filename;
$f1bn ~~ s/ \.sxml //;
$f1bn ~~ s/ $dir '/'? //;

my $f2bn = "some-file";
my $f2 = "$dir/$f2bn.html";


spurt( $filename, q:to/EOSX/);
$html [
  $body [
    $h1 [ Data from file ]
    $table [
      $tr [
        $th[ header ]
        $td[ data ]
      ]
    ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {
  C => {
    html => {
      doctype-show => True,
    },
    xml-show => True,
    xml-version => 1.1,
    xml-encoding => 'UTF-8',
    header-show => False,
  },

  S => {
    filename => $f2bn,                  # Default current file
    filepath => $dir,
    fileext => 'html',                  # Default xml
  },

#`{{
  option => {
    doctype => {
      show => 1,                        # Default 0
    },

    xml-prelude => {
      show => 1,                        # Default 0
      version => 1.1,                   # Default 1.0
      encoding => 'UTF-8',              # Default UTF-8
    }
  },

  output => {
    filename => $f2bn,                  # Default current file
    filepath => $dir,
    fileext => 'html',                  # Default xml
  }
}}
}

# Parse
my SemiXML::Sxml $x .= new( :trace, :merge, :refine([ <html pdf>]));
$x.parse( :$filename, :$config);

my Str $xml-text = ~$x;
note $xml-text;

like $xml-text, /:s '<?xml' 'version="1.1"' 'encoding="UTF-8"' '?>'/,
   'Xml prelude found';
like $xml-text, /:s '<!DOCTYPE' 'html>'/, 'Doctype found';

# Write xml out to file. Basename explicitly set.
$x.save(:filename($f1bn));
ok "$f1".IO ~~ :e, "File $f1 written";

# Write xml out to file. Filename named in prelude
$x.save;
ok $f2.IO ~~ :e, "File $f2 written";

#-------------------------------------------------------------------------------
# Cleanup
unlink $filename;
unlink $f1;
unlink $f2;
rmdir $dir;

done-testing;
exit(0);
