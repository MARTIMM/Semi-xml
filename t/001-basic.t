use v6.c;
use Test;


    use SemiXML;

    sub parse ( Str $content --> Str ) {

      state SemiXML::Sxml $x .= new;
      $x.parse(:$content);
      ~$x;
    }

my $xml = parse('$|st []');
is $xml, '<st/>', 'T0';
 
$xml = parse('$|st [ abc ]');
is $xml, '<st>abc</st>', 'T1';
 
$xml = parse(Q:q@$|st a1=w a2='g g' a3="h h" [ ]@);
like $xml, /'a1="w"'/, 'T2';
like $xml, /'a2="g g"'/, 'T3';
like $xml, /'a3="h h"'/, 'T4';
dies-ok { $xml = parse('$|st [ $|f w [] hj ]'); }, 'T5';
$xml = parse('$|t1 [ $|t2 [] $|t3[]]');
is $xml, '<t1><t2/><t3/></t1>', 'T6';
 
$xml = parse('$|t1 [ $**t2 [] $|t3[]]');
is $xml, '<t1> <t2/> <t3/></t1>', 'T7';
 
$xml = parse('$|t1 [ $|*t2 [] $|t3[]]');
is $xml, '<t1><t2/> <t3/></t1>', 'T8';
 
$xml = parse('$|t1 [ $*|t2 [] $|t3[]]');
is $xml, '<t1> <t2/><t3/></t1>', 'T9';


done-testing;
