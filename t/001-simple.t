use v6.c;
use Test;


    use SemiXML;

    sub parse ( Str $content --> Str ) {

      state SemiXML::Sxml $x .= new;
      $x.parse(:$content);
      ~$x;
    }
my $xml = parse('$st []');
is $xml, '<st/>', 'T0';
$xml = parse('$st [ abc ]');
is $xml, '<st>abc</st>', 'T1';
$xml = parse(Q:q@$st a1=w a2='g g' a3="h h" [ ]@);
like $xml, /'a1="w"'/, 'T2';
like $xml, /'a2="g g"'/, 'T3';
like $xml, /'a3="h h"'/, 'T4';


done-testing;
