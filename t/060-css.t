use v6;
use lib 'lib';

use Test;
use SemiXML::Sxml;
use XML::XPath;

#------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $html [
      $head [
        $!css.style compress=0 [
          $!css.reset type=minimalistic
          $!colors.palette base-rgb='#1200ff' type=blended mode=averaged


          $!css.b s='.infobox >' [
            $!css.b s=.message [
              border: 1px solid $*|sxml:color1;
              padding: 10px;

              $!css.b s='> .title' [
                color: $sxml:color5;
              ]
            ]
            $!css.b s=.user [
              border: 1px solid black;
              $!css.b s='> .title' [
                color: black;
              ]
            ]
          ]
        ]
      ]
    ]
    EOTXT

  my XML::XPath $p = get-xpath($text);
  #like $style-text, /:i 'background-color:#' <xdigit>**6 ';' /,
  #     'Found background color';
}

#------------------------------------------------------------------------------
sub get-xpath ( Str $content --> XML::XPath ) {

  my SemiXML::Sxml $x .= new;
  $x.parse(
    config => {
      ML => {
        :colors<SxmlLib::Colors>,
        :css<SxmlLib::Css>,
      }
    },
    :$content
  );

  # See the result
  my Str $xml-text = ~$x;
  diag $xml-text;

  XML::XPath.new(:xml($xml-text))
}

#------------------------------------------------------------------------------
done-testing;
