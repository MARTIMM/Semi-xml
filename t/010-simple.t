use v6.c;

use Test;
use SemiXML;

parse('$html a=x [ abc $a x=y [! pqr !] p534 tyu ]');




#-------------------------------------------------------------------------------
sub parse ( Str $content ) {

  state SemiXML::Sxml $x .= new;
  my ParseResult $r = $x.parse(:$content);
  ok $r ~~ Match, "match $content";
  #say "\nXML = " ~ $x;
}


#-------------------------------------------------------------------------------
# Cleanup
done-testing();
exit(0);


=finish

parse('$html xml:lang=en [ abc p534 ]');
parse('$svg:g a=b c="a b" [ def ]');

parse('$**text [ ]');
parse('$**x:text [ ]');

parse('$*|body [ ]');

parse('$|*body [ ]');

parse('$.Mod.meth a=b c="a b" [ ]');

parse('$!Mod.meth a=b c="a b" [ ]');
