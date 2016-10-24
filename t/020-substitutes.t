use v6.c;

use Test;
use SemiXML;

#-------------------------------------------------------------------------------
# prepare directory and create module
mkdir('t/M');
spurt( 't/M/m1.pm6', q:to/EOMOD/);
  use v6.c;
  use SemiXML;

  class M::m1 {
    has Hash $.symbols = {
      special-table => {
        tag-name => 'table',
        attributes => {
          class => 'big-table',
          id => 'new-table'
        }
      },
      special-td => {
        tag-name => 'td',
        attributes => {
          id => 'special-id'
        }
      }
    };
  }

  EOMOD

spurt( 't/M/m2.pm6', q:to/EOMOD/);
  use v6.c;
  use SemiXML;

  class M::m2 {
    # type error => no sumbols accessor
    has Hash $.symbls = {};
  }

  EOMOD

# setup the configuration
my Hash $config = {
  library       => { :mod1<t>, :mod2<t>},
  module        => { :mod1<M::m1>, :mod2<M::m2>}
}



# setup the contents to be parsed with a substitution item in it
my Str $content = '$.mod1.special-table data-x=tst []';

# instantiate parser and parse with contents and config
my SemiXML::Sxml $x .= new;
my ParseResult $r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

my $xml = $x.get-xml-text;
#say $xml;
like $xml, /'<table'/, "Found table";
like $xml, /'data-x="tst"'/, "Found data argument of table";
like $xml, /'id="new-table"'/, "Found id argument of table";



$content = '$.mod1.special-td [ data ]';
$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

$xml = $x.get-xml-text;
#say $xml;
like $xml, /'id="special-id"'/, "Found id argument of td";



$content = '$.mod2.xyz [ ]';

$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

$xml = $x.get-xml-text;
#say $xml;
like $xml, /'<undefined-method'/, "method undefined tag";
like $xml, /'method="symbols"'/, "method symbols undefined attribute";



$content = '$.mod3.xyz [ ]';

$r = $x.parse( :$config, :$content);
ok $r ~~ Match, "match $content";

$xml = $x.get-xml-text;
#say $xml;
like $xml, /'<undefined-module'/, "module undefined tag";
like $xml, /'module="mod3"'/, "module mod3 undefined attribute";

#-------------------------------------------------------------------------------
# Cleanup
done-testing();
unlink 't/M/m1.pm6';
unlink 't/M/m2.pm6';
rmdir 't/M';

exit(0);

