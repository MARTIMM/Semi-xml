use v6.c;
use Test;
use SemiXML;

#-------------------------------------------------------------------------------
# Testing;
#   Write file with config prelude
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
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
    filename => 'some-file',            # Default current file
    filepath => 't',
    fileext => 'html',                  # Default xml
  }
}

# Parse
my SemiXML::Sxml $x .= new;
$x.parse-file( :$filename, :$config);

my Str $xml-text = ~$x;
ok $xml-text ~~ ms/'<?xml' 'version="1.1"' 'encoding="UTF-8"' '?>'/,
   'Xml prelude found';
ok $xml-text ~~ ms/'<!DOCTYPE' 'html>'/, 'Doctype found';


#say $xml-text;

unlink $filename;

# Write xml out to file. Filename explicitly set.
#
$filename ~~ s/\.sxml//;
$x.save(:$filename);
ok "$filename.html".IO ~~ :e, "File $filename written";

unlink $filename;

# Write xml out to file. Filename named in prelude
#
$filename = 't/some-file.html';
$x.save;
ok $filename.IO ~~ :e, "File $filename written";

unlink $filename;

$filename = 't/another.html';
$x.save;
ok $filename.IO ~~ :!e, "File $filename not written";

$filename = 't/some-file.html';
ok $filename.IO ~~ :e, "File $filename written instead";

unlink $filename;

#-------------------------------------------------------------------------------
# Cleanup
done-testing();
exit(0);
