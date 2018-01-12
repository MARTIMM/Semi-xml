use v6;
use Test;
#use MONKEY-SEE-NO-EVAL;

      use SemiXML::Sxml;
      my SemiXML::Sxml $sxml .= new;
      isa-ok $sxml, SemiXML::Sxml;

      $sxml.parse(:content('$some-element []'));
      like ~$sxml, /'<some-element></some-element>'/,
      "The generated xml is conforming the standard";
          # unquoted value
      $sxml.parse(:content('$some-element attribute=value'));
      like ~$sxml, / 'attribute="value"' /,
                   'attribute without spaces in value';

      # double quoted value
      $sxml.parse(:content('$some-element attribute="v a l u e"'));
      like ~$sxml, / 'attribute="v a l u e"' /,
                   'attribute with double quoted value';

      # single quoted value
      $sxml.parse(:content("\$some-element attribute='v a l u e'"));
      like ~$sxml, / 'attribute="v a l u e"' /,
                   'attribute with single quoted value';

      # more than one attribute
      $sxml.parse(:content('$some-element a1=v1 a2=v2'));
      like ~$sxml, / 'a1="v1"' /, 'attribute a1 found';
      like ~$sxml, / 'a2="v2"' /, 'attribute a2 found';

      # boolean attributes
      $sxml.parse(:content('$some-element =a1 =!a2'));
      like ~$sxml, / 'a1="1"' /, 'true boolean attribute a1 found';
      like ~$sxml, / 'a2="0"' /, 'false boolean attribute a2 found';
          $sxml.parse(:content('$some-element [ $some-other-element ]'));
      like ~$sxml, / '<some-element>'
                     '<some-other-element></some-other-element>'
                     '</some-element>'
                   /, 'An element within another';
          $sxml.parse(:content('$some-element [ block 1 ][ block 2 ]'));
      like ~$sxml, / '<some-element>'
                     'block 1 block 2'
                     '</some-element>'
                   /, 'two blocks on an element';
          $sxml.parse(:content('$a1 { $a2 [ ] }'));
      like ~$sxml, / '<a1>$a2 [ ]</a1>' /, 'Inner element is not translated';
    

done-testing;
