use v6;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
my SemiXML::Sxml $x .= new( :trace, :refine([<in out>]));

my Hash $config = {
  C => {:tracing},
  T => { :parse, :!config},
};

my Hash $cc = {
  C => {:!tracing},
  F => { in => { self-closing => [ 'b', ], } },
  T => { :parse, :!config},
};

#-------------------------------------------------------------------------------
subtest 'body 1', {
  $x.parse(:content('$a [ ]'));
  like ~$x, / '<a></a>' /, "element a not self closing";

  $x.parse( :content('$a [ abc ]'));
  like ~$x, / '<a>abc</a>' /, 'element a can have content';

  $x.parse( :content('$a [ $b [ ] ]'));
  like ~$x, / '<a><b></b></a>' /, 'nested element b';

  $x.parse( :content('$a [ $b [ ] ]'), :config($cc));
  like ~$x, / '<a><b/></a>' /, "element b self closing";

  $x.parse( :content('$a [ $b [ abc ] ]'), :config($cc));
  like ~$x, / '<a><b/></a>' /, "element b cannot have content";

#`{{
  $x.parse(:content('$a [ ][ ]'), :$config);
  like ~$x, / '<a/>' /, ~$x;

  $x.parse(:content('$a [ a ][ b ]'), :$config);
  like ~$x, / '<a>a b</a>' /, ~$x;

  $x.parse(:content('$a { $a [ ] }[ b ]'));
  like ~$x, / '<a>$a [ ] b</a>' /, ~$x;

  $x.parse(:content('$a { abc ! ] > \} def }'), :$config);
  like ~$x, / '<a>abc ! ] &gt; } def</a>' /, ~$x;

  $x.parse(:content('$a « abc ! ] \» def »'), :$config);
  like ~$x, / '<a>abc ! ] » def</a>' /, ~$x;
}}
}

#-------------------------------------------------------------------------------
done-testing;
