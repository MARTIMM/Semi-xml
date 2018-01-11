use v6.c;

use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
subtest 'test oneliners', {

  my $xml = parse('$st');
  is $xml, '<st></st>', "1 tag: $xml";

  $xml = parse(Q:q@$st a1=w a2='g g' a3="h h" [ ]@);
  like $xml, /'a1="w"'/, 'a1 attribute';
  like $xml, /'a2="g g"'/, 'a2 attribute';
  like $xml, /'a3="h h"'/, 'a2 attribute';

  throws-like(
    { $xml = parse('$st [ $f w [] hj ]');},
    X::AdHoc, 'Parse failure',
    :message(/^ "Parse failure just after 'document'"/)
  );

  $xml = parse('$t1 [ $t2 [] $t3[]]');
  is $xml, '<t1><t2></t2><t3></t3></t1>', "nested tags: $xml";
}

#-------------------------------------------------------------------------------
subtest 'test multi liners', {

  my Str $xml = parse(Q:q:to/EOXML/);
    $aa [
      $bb [
      ]
    ]
    EOXML

  is $xml, '<aa><bb></bb></aa>', "2 tags: $xml";
#`{{
  try {
    $xml = parse(Q:q:to/EOXML/);
      $aa [
        $bb [ ][
          $cc [
        ]
      ]
      EOXML

    CATCH {

      default {
        like .message, /:s line 3\-4\, tag \$cc\, body number 1/,
             .message;
      }
    }
  }
}}

  $xml = parse(Q:q:to/EOXML/);
    $aa [
      $bb [ ][
        $cc [
      ]
       ]
    ]
    EOXML

  is $xml, '<aa><bb><cc></cc></bb></aa>', "3 tags: $xml";

  $xml = parse('$aa [ $bb { $x[abc] } ]');

  is $xml, '<aa><bb>$x[abc]</bb></aa>', "2 tags and preserving content: $xml";

}

#-------------------------------------------------------------------------------
sub parse ( Str $content is copy --> Str ) {

  state SemiXML::Sxml $x .= new( :!trace, :merge, :refine([<in-fmt out-fmt>]));
  my Bool $r = $x.parse(
    :$content,
    :config( { T => { :!config, :!parse} } )
  );
#  $content ~~ s:g/\n/ /;
#  $content ~~ s:g/\s+/ /;
#  ok $r, "match $content";

  my Str $xml = ~$x;
  $xml;
}

#-------------------------------------------------------------------------------
# Cleanup
done-testing();
exit(0);


=finish

parse('$html a=x [ abc $|*a x=y { pqr $xc [] } p534 tyu ]');


parse('$html xml:lang=en [ abc p534 ]');
parse('$svg:g a=b c="a b" [ def ]');

parse('$**text [ ]');
parse('$**x:text [ ]');

parse('$*|body [ ]');

parse('$|*body [ ]');

parse('$.Mod.meth a=b c="a b" [ ]');

parse('$!Mod.meth a=b c="a b" [ ]');
