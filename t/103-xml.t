use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Test $tag [ ... ]   Normal content
#   Test $tag [! ... !] Text only no child elements
#   Test $*tag [ ... ] Spacing around tags
#
#-------------------------------------------------------------------------------
# Setup
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
#!bin/sxml2xml.pl6
#
---
option/doctype/show:                    1;              # Default 0

option/xml-prelude/show:                1;              # Default 0
option/xml-prelude/version:             1.1;            # Default 1.0
option/xml-prelude/encoding:            UTF-8;          # Default UTF-8

output/filename:                        103-xml;        # Default 'x'
output/filepath:                        t;              # Default path '.'
output/fileext:                         html;           # Default xml
---
$html [
  $head [
    $style type=text/css [=
      .green {
        color: \#0f0;
        background-color: \#f0f;
      }
    ]
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
        $td[ data at $*<a href='http://example.com/' []
          $p [
            jhghjasdjhg asdhajh a $b [kjsdhfkj]sdjhkjh
            $*<u [kjdshkjh $*<b [hg]].
          ]
        ]
      ]
    ]
  ]
]
EOSX

# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
say $xml-text;


ok $xml-text ~~ ms/'<?xml' 'version="1.1"' 'encoding="UTF-8"' '?>'/,
   'Xml prelude found';
ok $xml-text ~~ ms/'<!DOCTYPE' 'html>'/, 'Doctype found';

ok $xml-text ~~ m/
'      .green {
        color: #0f0;
        background-color: #f0f;
      }
'
/, 'Check for literal text in css';

ok $xml-text ~~ m/
'      var a_tags = $(\'a\');
      var b = a_tags[1];
'
/, 'Check for literal text in javascript';

ok $xml-text ~~ ms/ '<tr>' '<th>' /, "'Th' after 'tr' found";

ok $xml-text ~~ ms/'data at <a href="http://example.com/"/><p>'/,
   "Testing \$* tag"
   ;

ok $xml-text ~~ ms/'a<b>kjsdhfkj</b>sdjhkjh <u>kjdshkjh <b>hg</b></u>.</p>'/,
   'Check part of result spacing tag $*<'
   ;


unlink $filename;

$filename = 't/103-xml.html';
$x.save;
ok $filename.IO ~~ :e, "File $filename written";

unlink $filename;


#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
