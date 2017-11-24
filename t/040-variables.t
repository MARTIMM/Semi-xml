use v6;
use lib 'lib';

use Test;
use SemiXML::Sxml;
use XML::XPath;

#------------------------------------------------------------------------------
subtest 'variables', {

  my $text = q:to/EOTXT/;
    $html [
      $!SxmlCore.var name=aCommonText [ $strong [Lorem ipsum dolor simet ...] ]
      $body [
        $h1 id=h1001 [ Introduction ]
        $p [ $sxml:aCommonText ]
        $ul [ $li [ $sxml:aCommonText ] ]
      ]
    ]
    EOTXT

  my SemiXML::Sxml $x .= new;
  $x.parse(content => $text);

  # See the result
  my Str $xml-text = ~$x;
  note $xml-text;

  my XML::XPath $p .= new(:xml($xml-text));

  is $p.find( '//p/strong/text()', :to-list)[0].text(),
     'Lorem ipsum dolor simet ...',
     'Found 1st substitution';

  is $p.find( '//ul/li/strong/text()', :to-list)[0].text(),
     'Lorem ipsum dolor simet ...',
     'Found 2nd substitution';

}

#------------------------------------------------------------------------------
subtest 'undeclared variable', {

  my $text = q:to/EOTXT/;
    $html [
      $body [
        $h1 id=h1001 [ Introduction ]
        $p [ $sxml:someCommonText ]
      ]
    ]
    EOTXT

  my SemiXML::Sxml $x .= new;
  $x.parse(content => $text);

  # See the result
  my Str $xml-text = ~$x;
  note $xml-text;

  my XML::XPath $p .= new(:xml($xml-text));

  is ~$p.find( '//p/sxml:someCommonText', :to-list),
     '<sxml:someCommonText/>',
     'Found undeclared variable';
}

#------------------------------------------------------------------------------
subtest 'generated variables', {

  my $text = q:to/EOTXT/;
    $html [
      $!SxmlCore.colors base-color='#1200ff'
      $head [
        $style [
          strong {
            color: $sxml:base-color;
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
  $x.parse(content => $text);

  # See the result
  my Str $xml-text = ~$x;
  diag $xml-text;

  my XML::XPath $p .= new(:xml($xml-text));

  like $p.find( '//style/text()', :to-list)[0].text,
       / 'color:#1200ff;' /, 'Found undeclared variable';
}

#------------------------------------------------------------------------------
done-testing;
