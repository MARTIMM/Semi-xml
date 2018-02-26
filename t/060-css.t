use v6;

use Test;
use SemiXML::Sxml;
use XML::XPath;

#-------------------------------------------------------------------------------
subtest 'generated blended color variables', {

  my $text = q:to/EOTXT/;
    $html [
      $head [
        $!css.reset type=condensed-universal []

        $!colors.palette base-rgb='#1200ff' type=blended mode=averaged []

        $!css.style [

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
  my Array $style-text = [$p.find( '//style/text()', :to-list)];
  like $style-text[0].text, /'font-weight: inherit;'/,
       'found some of the reset';
  like $style-text[1].text, /'.infobox > .message > .title'/,
       'found a selector line';
}

#-------------------------------------------------------------------------------
sub get-xpath ( Str $content --> XML::XPath ) {

  my SemiXML::Sxml $x .= new(:refine(['html','html']));
  $x.parse(
    config => {
      ML => {
        :colors<SxmlLib::Colors>,
        :css<SxmlLib::Html::Css>,
      },
      T => {:!parse}
    },
    :$content,
    :!trace, :!raw, :!keep, :exec
  );

  # See the result
  my Str $xml-text = ~$x;
  #diag $xml-text;
  $x.done;

  XML::XPath.new(:xml($xml-text))
}

#-------------------------------------------------------------------------------
done-testing;
