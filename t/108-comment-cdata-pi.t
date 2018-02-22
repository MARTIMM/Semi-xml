use v6;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Setup
my $dir = 't/D108';
mkdir $dir unless $dir.IO ~~ :e;
my $f1 = "$dir/test-file.sxml";

spurt( $f1, q:to/EOSX/);
$html [
  $body [
    $h1 [ Tests for comments etc ]

    $sxml:comment [ comment text ]
    $sxml:comment [ comment text $!SxmlCore.date ]
    $sxml:comment [ comment text $p [ data in section ] $br ]

    $sxml:cdata [cdata text]
    $sxml:cdata [cdata text $!SxmlCore.date ]
    $sxml:cdata [cdata text $p [ data in section ] $br ]

    $sxml:pi target=perl6 [ instruction text ]
    $sxml:pi target=xml-stylesheet [href="mystyle.css" type="text/css"]

    $h1 [ End of tests ]
  ]
]
EOSX

#-------------------------------------------------------------------------------
my Hash $config = {
#`{{
  F => {
    xio => {
      inline => [ 'sxml:SxmlCore.date', 'sxml:SxmlCore.date-time' ],
      self-close => [ 'br' ],
    }
  },
}}
#  S => { xio => { :fileext<html>, }, },
  #C => { xio => { :!xml-show, :!doctype-show, }, },
  T => {:parse}
};

#-------------------------------------------------------------------------------
# Parse
my SemiXML::Sxml $x .= new(:refine[<html html>]);
$x.parse( :filename($f1), :$config, :!trace);
my Str $xml-text = ~$x;
#diag $xml-text;

my $d = Date.today();
like $xml-text, /:s '<!--' comment text '-->'/, 'Check comments';
like $xml-text, /:s '<!--' comment text \d**4 '-' \d\d '-' \d\d '-->'/,
   'Check comments with other method';
like $xml-text, /:s '<!--' comment text
                    '<p>' data in section '</p>'
                    '<br/>' '-->'
                /,
   'Check comments with embedded tags';

like $xml-text, /:s '<![' CDATA '[' cdata text ']]>'/, 'Check cdata';
like $xml-text, /:s '<![' CDATA '[' cdata text \d**4 '-' \d\d '-' \d\d ']]>'/,
   'Check cdata with other method';
like $xml-text, /:s '<![' CDATA '[' cdata text
                    '<p>' data in section '</p>'
                    '<br/>' ']]>'
                /, 'Check cdata with embedded tags';

like $xml-text, /:s '<?' perl6 instruction text '?>'/, 'Check pi data 1';
like $xml-text, /'<?xml-stylesheet href="mystyle.css" type="text/css"?>'
                /, 'Check pi data 2';


#-------------------------------------------------------------------------------
# Cleanup
#unlink $f1;
#rmdir $dir;

done-testing();
