use v6;
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
    xml-show => True,
    header-show => True,
  },

  X => {
    xml-version => 1.1,
  },

  H => {
    html => {
      Content-Type => 'text/html; charset="utf-8"',
    },
  },

  S => {
    filename => $f2bn,                  # Default current file
    rootpath => $dir,
    fileext => 'html',                  # Default xml
  },
}

# Parse
my SemiXML::Sxml $x .= new( :!trace, :merge, :refine([<html html>]));
$x.parse( :$filename, :$config);

my Str $xml-text = ~$x;
#note "Xml:\n", $xml-text;

like $xml-text, /:s 'text/html; charset="utf-8"'/, 'header found';
like $xml-text, /:s '<?xml' 'version="1.1"' 'encoding="UTF-8"' '?>'/,
   'Xml prelude found';
like $xml-text, /:s '<!DOCTYPE' 'html>'/, 'Doctype found';

# Write xml out to file.
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
