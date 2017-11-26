use v6;
use lib 'lib';

use Test;
use SemiXML::Sxml;
use XML::XPath;

#------------------------------------------------------------------------------
subtest 'generated averaged color variables', {

  my $text = q:to/EOTXT/;
    $html [
      $!Colors.palette base-rgb='#1200ff' type=averaged
      $head [
        $style [
          strong {
            color: $sxml:base-color;
            border-color: $sxml:color-two;
            background-color: $sxml:color-five;
          }
        ]
      ]
      $body [
        $h1 id=h1001 [ Introduction ]
        $p [ $strong [some text] ]
      ]
    ]
    EOTXT

  my SemiXML::Sxml $x .= new;
  $x.parse(
    config => {
      ML => {:Colors<SxmlLib::Colors>,}
    },
    content => $text
  );

  # See the result
  my Str $xml-text = ~$x;
  diag $xml-text;

  my XML::XPath $p .= new(:xml($xml-text));

  my Str $style-text = $p.find( '//style/text()', :to-list)[0].text;
  like $style-text, /:i 'color:#1200ff;' /, 'Found base color';
  like $style-text, /:i 'border-color:#' <xdigit>**6 ';' /, 'Found border color';
  like $style-text, /:i 'background-color:#' <xdigit>**6 ';' /,
       'Found background color';
}

#------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $html [
      $!SxmlCore.palette base-rgb='#1200ff' type=blended
      $head [
        $style [
          strong {
            color: $sxml:base-color;
            border-color: $sxml:color-two;
            background-color: $sxml:color-five[]_map;
          }
        ]
      ]
      $body [
        $h1 id=h1001 [ Introduction ]
        $p [ $strong [some text] ]
      ]
    ]
    EOTXT

  my SemiXML::Sxml $x .= new;
  $x.parse(
    config => {
      ML => {:Colors<SxmlLib::Colors>,},
    },
    content => $text
  );



  # See the result
  my Str $xml-text = ~$x;
  diag $xml-text;

  my XML::XPath $p .= new(:xml($xml-text));

  my Str $style-text = $p.find( '//style/text()', :to-list)[0].text;
  like $style-text, /:i 'color:#1200ff;' /, 'Found base color';
  like $style-text, /:i 'border-color:#' <xdigit>**6 ';' /, 'Found border color';
  like $style-text, /:i 'background-color:#' <xdigit>**6 ';' /,
       'Found background color';
}

#------------------------------------------------------------------------------
done-testing;
