use v6;
use lib 'lib';

use Test;
use SemiXML::Sxml;
use XML::XPath;

#-------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $html [
      $head [
        $!css.style compress=0 =!map [
          $!css.reset type=condensed-universal []
          $!colors.palette base-rgb='#1200ff' type=blended mode=averaged []

          $!css.b s='.infobox >' [
            $!css.b s=.message [
              border: 1px solid $sxml:var-ref name=blend-color1 [];
              padding: 10px;

              $!css.b s='> .title' [
                color: $sxml:var-ref name=blend-color5 [];
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
  my Str $style-text = $p.find('//style/text()').text;
  like $style-text, /'font-weight: inherit;'/, 'Found some of the reset';
  like $style-text, /'.infobox > .message > .title'/, 'found a selector line';
}

#-------------------------------------------------------------------------------
sub get-xpath ( Str $content --> XML::XPath ) {

  my SemiXML::Sxml $x .= new(:refine(['html','html']));
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
  #diag $xml-text;

  XML::XPath.new(:xml($xml-text))
}

#-------------------------------------------------------------------------------
done-testing;
