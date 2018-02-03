use v6;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Test $tag [ ... ]   Normal content
#   Test $tag « ... »   Text only no child elements
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
    $style type=text/css «
      green {
        color: #0f0;
        background-color: #f0f;
      }
    »
    $script «
      var a_tags = $('a');
      var b = a_tags[1];
    »
  ]

  $body [
    $h1 class=green [ Data from file ]
    $table [
      $tr [
        $th[ header ]
        $td[ data at $a href='http://example.com/' []
          $p [
            bla bla $b [bla] bla $u [bla $b [bla]].
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
    out-fmt => { :doctype-show, :xml-show },
  },

  F => {
    in-fmt => {
      space-preserve => [<style>,]
    }
  },

  S => {
    out-fmt => {
      filename => 'f1',
      rootpath => 't/D103',
      fileext => 'html',
    }
  },

  T => {
    :tables, :parse, :file-handling
  },

  X => {
    out-fmt => {
      xml-version => 1.1,
      xml-encoding => 'UTF-8',
    }
  },
}

# Parse
my SemiXML::Sxml $x .= new(:refine([<in-fmt out-fmt>]));
$x.parse( :filename($f1), :$config, :!trace, :!raw, :!keep);

my Str $xml-text = ~$x;
#diag $xml-text;


like $xml-text, /:s '<?' xml version '="1.1"' encoding '="UTF-8"' '?>' /,
     'Xml prelude found';
like $xml-text, /:s '<!' DOCTYPE html '>' /, 'Doctype found';

ok $xml-text ~~ m/
'green {
  color: #0f0;
  background-color: #f0f;
}'
/, 'Check for literal text in css';

like $xml-text, /:s var a_tags '=' "\$('a');" var b '=' a_tags/,
   'Check for literal text in javascript';

ok $xml-text ~~ ms/ '<tr>' '<th>' /, "'Th' after 'tr' found";

$x.save;
ok $f2.IO ~~ :e, "File $f2 written";


#-------------------------------------------------------------------------------
# Cleanup

unlink $f1;
unlink $f2;
rmdir $dir;

done-testing();
exit(0);
