use v6;
use lib 'lib';

use Test;
use SemiXML::Sxml;
use XML::XPath;

#-------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $x [
      $!Colors.palette outspec=rgbhex base-rgb='#1200ff'
                       type=blended mode=averaged
      $set0 [ $sxml:var-ref name=base-color ]
      $set1 [
        $sxml:var-ref name=blend-color1 $sxml:var-ref name=blend-color2
        $sxml:var-ref name=blend-color3 $sxml:var-ref name=blend-color4
        $sxml:var-ref name=blend-color5
      ]
      $set2 [ $sxml:var-ref name=blend-color6 ]
    ]
    EOTXT

  my XML::XPath $p = get-xpath($text);

  my Str $c = $p.find( '/x/set0/text()', :to-list)[0].text;
  like $c, /:i '#1200ff' /, 'Found base color';

  $c = $p.find( '/x/set1/text()', :to-list)[0].text;
  ok $c ~~ / [ '#' <xdigit>**6 ]**5 /, 'Found 5 other colors in set 1';

  $c = $p.find( '/x/set2/text()', :to-list)[0].text;
  ok !$c, 'There is no 6th color';



  $text = q:to/EOTXT/;
    $x [
      $!Colors.palette
        base-rgb='#1200ff' type=blended mode=hard opacity=0.8
        ncolors=10
      $set0 [ $sxml:var-ref name=base-color ]
      $set1 [
        $sxml:var-ref name=blend-color1 $sxml:var-ref name=blend-color2
        $sxml:var-ref name=blend-color3 $sxml:var-ref name=blend-color4
        $sxml:var-ref name=blend-color5
      ]
      $set2 [ $sxml:var-ref name=blend-color6 $sxml:var-ref name=blend-color9 ]
    ]
    EOTXT

  $p = get-xpath($text);
  $c = $p.find( '/x/set2/text()', :to-list)[0].text;
  ok $c ~~ / [ '#' <xdigit>**6 ]**2 /, 'Found 6th and 9th color2 in set 2';
}

#-------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $html [
      $!Colors.palette outspec=rgbhex base-rgb='#1200ffff'
                       type=blended mode=hard
      $head [
        $style [
          $strong [
            color: $sxml:var-ref name=base-color [];
            border-color: $sxml:var-ref name=blend-color2 [];
            background-color: $sxml:var-ref name=blend-color5 [];
          ]
        ]
      ]
      $body [
        $h1 id=h1001 [ Introduction ]
        $p [ $strong [some text] ]
      ]
    ]
    EOTXT

  my XML::XPath $p = get-xpath($text);

  my Str $style-text = $p.find( '//style/strong/text()', :to-list)[0].text;
  like $style-text, /:i 'color:#1200ffff;' /, 'Found base color';
  like $style-text, /:i 'border-color:#' <xdigit>**8 ';' /,
       'Found border color';
  like $style-text, /:i 'background-color:#' <xdigit>**8 ';' /,
       'Found background color';
}

#-------------------------------------------------------------------------------
subtest 'generate monochromatic color variables', {

  my $text = q:to/EOTXT/;
    $x [
      $!Colors.palette base-hsl=<0 100 50> type=color-scheme mode=monochromatic
                       lighten=20 ncolors=6 outspec=hsl set-name=mono
      $set1 [
        $sxml:var-ref name=mono-scheme-color1
        $sxml:var-ref name=mono-scheme-color2
        $sxml:var-ref name=mono-scheme-color3
        $sxml:var-ref name=mono-scheme-color4
        $sxml:var-ref name=mono-scheme-color5
        $sxml:var-ref name=mono-scheme-color6
      ]
    ]
    EOTXT

  my XML::XPath $p = get-xpath($text);

  my Str $style-text = $p.find( '//set1/text()', :to-list)[0].text;
  like $style-text, / 'hsla(0.0,100.0%,20.0%)' /, 'Found color 2';
  like $style-text, / 'hsla(0.0,100.0%,80.0%)' /, 'Found 5th color';
}

#-------------------------------------------------------------------------------
sub get-xpath ( Str $content --> XML::XPath ) {

  my SemiXML::Sxml $x .= new(:!trace);
  $x.parse(
    config => {
      F => { xml => { space-preserve => [<set0 set1 set2>], }, },
      ML => { :Colors<SxmlLib::Colors>, },
      T => { :config, :tables, :modules, :parse, },
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
