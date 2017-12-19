use v6;
use Test;
#use MONKEY-SEE-NO-EVAL;

use SemiXML::Sxml;
my SemiXML::Sxml $sxml .= new;
isa-ok $sxml, SemiXML::Sxml;

$sxml.parse(:content('$some-element []'));
my $xml = ~$sxml;

is $xml, qq@<?xml version="1.0" encoding="UTF-8"?>\n<some-element/>@,
   "The generated xml is conforming the standard";
subtest 'jhg djhgasd asjh', {
  is 1,1,'yes one is one';
  is 2,2,'and two is two';
  is 2,3,'and two is not three';
  
  throws-like { Failure.new('awkward'); },
    Exception, 'return a failure', :message('not so awkward');
}

todo 'working on it', 1 unless 0;
subtest 'jhgj jh jh jhg', {
  is 15,14,'not yet, maybe later'; 
}


done-testing;
