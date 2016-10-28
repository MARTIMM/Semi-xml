use v6.c;

use Test;
use SemiXML;

my $xml = parse('$st []');
is $xml, '<st/>', "1 tag: $xml";

$xml = parse(Q:q@$st a1=w a2='g g' a3="h h" [ ]@);
like $xml, /'a1="w"'/, 'a1 attribute';
like $xml, /'a2="g g"'/, 'a2 attribute';
like $xml, /'a3="h h"'/, 'a2 attribute';

#dies-ok { $xml = parse('$st [ $f w [] hj ]'); }, 'Parse failure';

try {
  $xml = parse('$st [ $f w [] hj ]');

  CATCH {
    default {
      my $m = .message;
      $m ~~ s/\n/ /;
      like $m, /^ "Parse failure just after 'tag specification'"/, $m;
    }
  }
}

$xml = parse('$t1 [ $t2 [] $t3[]]');
is $xml, '<t1><t2/><t3/></t1>', "nested tags: $xml";

$xml = parse('$t1 [ $**t2 [] $t3[]]');
is $xml, '<t1> <t2/> <t3/></t1>', "nested tags with \$**: $xml";

$xml = parse('$t1 [ $|*t2 [] $t3[]]');
is $xml, '<t1><t2/> <t3/></t1>', "nested tags with \$|*: $xml";

$xml = parse('$t1 [ $*|t2 [] $t3[]]');
is $xml, '<t1> <t2/><t3/></t1>', "nested tags with \$*|: $xml";

#-------------------------------------------------------------------------------
sub parse ( Str $content --> Str ) {

  state SemiXML::Sxml $x .= new;
  my ParseResult $r = $x.parse(:$content);
  ok $r ~~ Match, "match $content";

  my Str $xml = ~$x;
  $xml;
}

#-------------------------------------------------------------------------------
# Cleanup
done-testing();
exit(0);


=finish

parse('$html a=x [ abc $|*a x=y [! pqr $xc [] !] p534 tyu ]');


parse('$html xml:lang=en [ abc p534 ]');
parse('$svg:g a=b c="a b" [ def ]');

parse('$**text [ ]');
parse('$**x:text [ ]');

parse('$*|body [ ]');

parse('$|*body [ ]');

parse('$.Mod.meth a=b c="a b" [ ]');

parse('$!Mod.meth a=b c="a b" [ ]');

