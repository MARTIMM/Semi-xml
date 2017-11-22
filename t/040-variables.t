use v6;
use lib 'lib';

use Test;
use SemiXML::Sxml;
use XML::XPath;

#------------------------------------------------------------------------------
subtest 'var test 1', {

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
done-testing;
