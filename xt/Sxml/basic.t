use v6;
use Test;
#use MONKEY-SEE-NO-EVAL;

      use SemiXML::Sxml;
      my SemiXML::Sxml $sxml .= new;
      isa-ok $sxml, SemiXML::Sxml;

      $sxml.parse(:content('$some-element []'));
      like ~$sxml, /'<some-element></some-element>'/,
      "The generated xml is conforming the standard";
    

done-testing;
