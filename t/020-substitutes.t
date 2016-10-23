use v6.c;

use Test;
use SemiXML;

my $xml = parse('$st []');
is $xml, '<st/>', "Found $xml";

#$xml = parse('$st [ $f w [] hj ]');


#-------------------------------------------------------------------------------
sub parse ( Str $content --> Str ) {

  state SemiXML::Sxml $x .= new;
  my ParseResult $r = $x.parse(:$content);
  ok $r ~~ Match, "match $content";

  my Str $xml = $x.get-xml-text;
say "XML doc: ", $xml;
  $xml;
}


#-------------------------------------------------------------------------------
# Cleanup
done-testing();
exit(0);



parse('$html a=x [ abc $|*a x=y [! pqr $xc [] !] p534 tyu ]');


parse('$html xml:lang=en [ abc p534 ]');
parse('$svg:g a=b c="a b" [ def ]');

parse('$**text [ ]');
parse('$**x:text [ ]');

parse('$*|body [ ]');

parse('$|*body [ ]');

parse('$.Mod.meth a=b c="a b" [ ]');

parse('$!Mod.meth a=b c="a b" [ ]');

