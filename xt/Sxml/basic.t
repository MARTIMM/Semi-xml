use v6;
use Test;
#use MONKEY-SEE-NO-EVAL;

use SemiXML::Sxml;
my SemiXML::Sxml $sxml .= new;
isa-ok $sxml, SemiXML::Sxml;

$sxml.parse(:content('$some-element []'));
is ~$sxml, qq@<?xml version="1.0" encoding="UTF-8"?>\n<some-element/>@,
"The generated xml is conforming the standard";
$sxml.parse(:content('$some-element attribute=value'));
like ~$sxml, / 'attribute="value"' /,
             'attribute without spaces in value';

$sxml.parse(:content('$some-element attribute="v a l u e"'));
like ~$sxml, / 'attribute="v a l u e"' /,
             'attribute with double quoted value';

$sxml.parse(:content("\$some-element attribute='v a l u e'"));
like ~$sxml, / 'attribute="v a l u e"' /,
             'attribute with single quoted value';

$sxml.parse(:content('$some-element attribute=<v a l u e>'));
like ~$sxml, / 'attribute="v a l u e"' /,
             'attribute with bracketed <> value';

$sxml.parse(:content('$some-element a1=v1 a2=v2'));
like ~$sxml, / 'a1="v1"' /, 'attribute a1 found';
like ~$sxml, / 'a2="v2"' /, 'attribute a2 found';

# Cannot test false attribute because the \! triggers a closing block
# somehow. This is a grammar problem.
$sxml.parse(:content('$some-element =a1'));
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
!= <sxml.parse/>(:content("\$a1 [! \$a2 [

done-testing;
