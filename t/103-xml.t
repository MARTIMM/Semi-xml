use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Test $tag [ ... ]   Normal content
#   Test $tag [! ... !] Text only no child elements
#   Test $*!tag [ ... ] Spacing around tags
#
#-------------------------------------------------------------------------------
# Setup
my $dir = 't/D103';
mkdir $dir unless $dir.IO ~~ :e;
my $f1 = "$dir/test-file.sxml";

my $f2 = 't/D103/f1.html';

spurt( $f1, q:to/EOSX/);
$html [
  $head [
    $style type=text/css [!=
      green {
        color: #0f0;
        background-color: #f0f;
      }
    !]
    $script [!=
      var a_tags = $('a');
      var b = a_tags[1];
    !]
  ]

  $body [
    $h1 class=green [ Data from file ]
    $table [
      $tr [
        $th[ header ]
        $td[ data at $*|a href='http://example.com/' []
          $p [
            bla bla $b [bla] bla $*|u [bla $b [bla]].
          ]
        ]
      ]
    ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {
  C => {
    out-fmt => {
      doctype-show => True,
      xml-show => True,
    },
  },

  X => {
    out-fmt => {
      xml-version => 1.1,
      xml-encoding => 'UTF-8',
    }
  },

  S => {
    out-fmt => {
      filename => 'f1',
      rootpath => 't/D103',
      fileext => 'html',
    }
  }
}

# Parse
my SemiXML::Sxml $x .= new( :!trace, :merge, :refine([<in-fmt out-fmt>]));
$x.parse( :filename($f1), :$config);

my Str $xml-text = ~$x;
#note $xml-text;


ok $xml-text ~~ ms/'<?xml' 'version="1.1"' 'encoding="UTF-8"' '?>'/,
   'Xml prelude found';
ok $xml-text ~~ ms/'<!DOCTYPE' 'html>'/, 'Doctype found';

ok $xml-text ~~ m/
'green {
  color: #0f0;
  background-color: #f0f;
}'
/, 'Check for literal text in css';

ok $xml-text ~~ ms/var a_tags '=' "\$('a');" var b '=' a_tags/,
   'Check for literal text in javascript';

ok $xml-text ~~ ms/ '<tr>' '<th>' /, "'Th' after 'tr' found";

ok $xml-text ~~ ms/'data at <a href="http://example.com/"/><p>'/,
   "Testing \$* tag"
   ;

like $xml-text, / :s "bla<b>bla</b>bla <u>bla<b>bla</b></u>."/,
     'Check part of result spacing tag $*|';


$x.save;
ok $f2.IO ~~ :e, "File $f2 written";


#-------------------------------------------------------------------------------
# Cleanup

unlink $f1;
unlink $f2;
rmdir $dir;

done-testing();
exit(0);
