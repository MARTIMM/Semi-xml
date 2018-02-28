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

          body { background-color: orange; }

          $!css.b s='.infobox >' [
            $!css.b s=.message [
              border: 1px solid $sxml:var-ref name=blend-color1 [];
              padding: 10px;

              $!css.b s='> .title' [
                color: $sxml:var-ref name=blend-color5 [];
              ]
            ]

            $!css.b s=.user [
              border: 2px solid black;
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
  like $style-text[1].text, /'solid #' <xdigit>+/, 'found border color';
  like $style-text[1].text, /'color: #' <xdigit>+/, 'found title color';
  like $style-text[1].text, /'border: 1px'/, 'found border under message';
  like $style-text[1].text, /'border: 2px'/, 'found border under user';
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
  mkdir 't/D060' unless 't/D060'.IO ~~ :e;
  't/D060/css.html'.IO.spurt($x.Str);
  $x.done;

  XML::XPath.new(:xml($x.Str))
}

#-------------------------------------------------------------------------------
done-testing;

#unlink('t/D060/css.html');
#rmdir('t/D060');
