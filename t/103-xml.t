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
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
$|html [
  $|head [
    $|style type=text/css [!=
      green {
        color: #0f0;
        background-color: #f0f;
      }
    !]
    $|script [!=
      var a_tags = $('a');
      var b = a_tags[1];
    !]
  ]

  $|body [
    $|h1 class=green [ Data from file ]
    $|table [
      $|tr [
        $|th[ header ]
        $|td[ data at $*|a href='http://example.com/' []
          $|p [
            bla bla $|b [bla] bla $*|u [bla $|b [bla]].
          ]
        ]
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
    filename => '103-xml',              # Default current file
    filepath => 't',                    # Default path '.'
    fileext => 'html',                  # Default xml
  }
}

# Parse
#
my SemiXML::Sxml $x .= new;
$x.parse-file( :$filename, :$config);

my Str $xml-text = ~$x;
#say $xml-text;


ok $xml-text ~~ ms/'<?xml' 'version="1.1"' 'encoding="UTF-8"' '?>'/,
   'Xml prelude found';
ok $xml-text ~~ ms/'<!DOCTYPE' 'html>'/, 'Doctype found';

ok $xml-text ~~ m/
'green {
  color: #0f0;
  background-color: #f0f;
}'
/, 'Check for literal text in css';

#ok $xml-text ~~ ms/var a_tags '=' '$(\'a\');' var b '=' a_tags\[1\];/,
ok $xml-text ~~ ms/var a_tags '=' "\$('a');" var b '=' a_tags/,
   'Check for literal text in javascript';

ok $xml-text ~~ ms/ '<tr>' '<th>' /, "'Th' after 'tr' found";

ok $xml-text ~~ ms/'data at <a href="http://example.com/"/><p>'/,
   "Testing \$* tag"
   ;

like $xml-text, / :s "bla<b>bla</b>bla <u>bla<b>bla</b></u>."/,
     'Check part of result spacing tag $*|';


unlink $filename;

$filename = 't/103-xml.html';
$x.save;
ok $filename.IO ~~ :e, "File $filename written";

unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done-testing();
exit(0);
