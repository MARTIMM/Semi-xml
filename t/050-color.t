use v6;
use lib 'lib';

use Test;
use SemiXML::Sxml;
use XML::XPath;

#-------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $x [
      $!Colors.palette base-rgb='#1200ff' type=blended mode=averaged
      $set0 [$sxml:base-color]
      $set1 [$sxml:color1 $sxml:color2 $sxml:color3 $sxml:color4 $sxml:color5]
      $set2 [$sxml:color6]
    ]
    EOTXT

  my XML::XPath $p = get-xpath($text);

  my Str $c = $p.find( '/x/set0/text()', :to-list)[0].text;
  like $c, /:i '#1200ff' /, 'Found base color';

  $c = $p.find( '/x/set1/text()', :to-list)[0].text;
  ok $c ~~ / [ '#' <xdigit>**8 ]**5 /, 'Found 5 other colors in set 1';

  $c = $p.find( '/x/set2/text()', :to-list)[0].text;
  ok !$c, 'There is no 6th color';



  $text = q:to/EOTXT/;
    $x [
      $!Colors.palette
        base-rgb='#1200ff' type=blended mode=hard opacity=0.8
        ncolors=10
      $set0 [$sxml:base-color]
      $set1 [$sxml:color1 $sxml:color2 $sxml:color3 $sxml:color4 $sxml:color5]
      $set2 [$sxml:color6 $sxml:color9]
    ]
    EOTXT

  $p = get-xpath($text);
  $c = $p.find( '/x/set2/text()', :to-list)[0].text;
  ok $c ~~ / [ '#' <xdigit>**8 ]**2 /, 'Found 6th and 9th color2 in set 2';
}

#-------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $html [
      $!Colors.palette base-rgb='#1200ff' type=blended mode=hard
      $head [
        $style [
          strong {
            color: $sxml:base-color;
            border-color: $sxml:color2;
            background-color: $sxml:color5;
          }
        ]
      ]
      $body [
        $h1 id=h1001 [ Introduction ]
        $p [ $strong [some text] ]
      ]
    ]
    EOTXT

  my XML::XPath $p = get-xpath($text);

  my Str $style-text = $p.find( '//style/text()', :to-list)[0].text;
  like $style-text, /:i 'color:#1200ffff;' /, 'Found base color';
  like $style-text, /:i 'border-color:#' <xdigit>**8 ';' /, 'Found border color';
  like $style-text, /:i 'background-color:#' <xdigit>**8 ';' /,
       'Found background color';
}

#`{{
#-------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $x [
      $!Colors.palette base-rgb='#1200ff' type=blended mode=hard
      $y [
        $!Colors.darken name=cd c='#1200ff' p=20 []
        $!Colors.lighten name=cl p=20 [$sxml:color2]
      ]
    ]
    EOTXT

  my XML::XPath $p = get-xpath($text);

  my Str $style-text = $p.find( '//style/text()', :to-list)[0].text;
  like $style-text, /:i 'color:#1200ffff;' /, 'Found base color';
  like $style-text, /:i 'border-color:#' <xdigit>**8 ';' /, 'Found border color';
  like $style-text, /:i 'background-color:#' <xdigit>**8 ';' /,
       'Found background color';
}
}}

#-------------------------------------------------------------------------------
sub get-xpath ( Str $content --> XML::XPath ) {

  my SemiXML::Sxml $x .= new;
  $x.parse(
    config => {
      ML => {:Colors<SxmlLib::Colors>,}
    },
    :$content
  );

  # See the result
  my Str $xml-text = ~$x;
  diag $xml-text;

  XML::XPath.new(:xml($xml-text))
}

#-------------------------------------------------------------------------------
done-testing;
