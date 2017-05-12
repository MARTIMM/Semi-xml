use v6.c;

use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
my Str $dir = 't/D210';
mkdir $dir unless $dir.IO ~~ :e;
my Str $cfg = "$dir/SemiXML.toml";
my Str $sxml = "$dir/t210.sxml";

#-------------------------------------------------------------------------------
subtest 'self-closing', {

  spurt $cfg, qq:to/EOCONFIG/;
    [ F.t210 ]
    self-closing = [ 'e1', 'e2']
    EOCONFIG

  spurt $sxml, Q:to/EOSXML/;
    $top [
    $e1                         # stays ok
    $e2 [ abc def ]             # content will be dropped
    $e3                         # content of ' ' added
    $e4 [ non empty element ]   # stays ok
    ]
    EOSXML

  my SemiXML::Sxml $x;
  $x .= new( :trace, :merge, :refine([ <t210 xml>]));
  isa-ok $x, 'SemiXML::Sxml';

  $x.parse(:filename($sxml));
  my Str $xml-text = ~$x;
  #note $xml-text;
  like $xml-text, /'<e1/>'/, 'e1 ok';
  like $xml-text, /'<e2/>'/, 'e2 ok';
  like $xml-text, /'<e3></e3>'/, 'e3 ok';
  like $xml-text, /'<e4>non empty element</e4>'/, 'e3 ok';
}

#-------------------------------------------------------------------------------
subtest 'self-closing on html defaults', {

  spurt $sxml, Q:to/EOSXML/;
    $html [
      $head [
        $title
        $meta  charset=UTF-8
      ]

      $body [
        $h1 [ test ]
        $p
        $hr
        $p [ $b [bold] $br ]
      ]
    ]
    EOSXML

  my SemiXML::Sxml $x;
  $x .= new( :trace, :merge, :refine([ <html html>]));
  isa-ok $x, 'SemiXML::Sxml';

  $x.parse(:filename($sxml));
  my Str $xml-text = ~$x;
  #note $xml-text;
  like $xml-text, /'<title></title>'/, 'empty title found';
  like $xml-text, /'<meta charset="UTF-8"/>'/, 'meta found';
  like $xml-text, /'<p></p>'/, 'empty p found';
  like $xml-text, /'<br/>'/, 'br ok';
  like $xml-text, /'<hr/>'/, 'hr ok';
}

#-------------------------------------------------------------------------------
# Cleanup
done-testing();
unlink $cfg;
unlink $sxml;
rmdir $dir;

exit(0);
