use v6;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------

my SemiXML::Sxml $x .= new( :trace, :refine([<in out>]));

my Hash $config = {
  T => {:parse},
  C => {:tracing}
};

#-------------------------------------------------------------------------------
subtest 'body 1', {
  $x.parse(:content('$a [ ][ ]'));
  like ~$x, / '<a/>' /, ~$x;

  $x.parse(:content('$a [ a ][ b ]'));
  like ~$x, / '<a>ab</a>' /, ~$x;

  $x.parse(:content('$a [! $a [ ] !][ b ]'));
  like ~$x, / '<a>$a [ ] b</a>' /, ~$x;

  $x.parse(:content('$a [! abc ! def !]'), :$config);
  like ~$x, / '<a>abc ! def</a>' /, ~$x;
}

#-------------------------------------------------------------------------------
done-testing;
