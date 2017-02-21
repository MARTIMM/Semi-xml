use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
my Str $dir = 't/D200';
my Str $cfg = "$dir/SemiXML.toml";
mkdir $dir unless $dir.IO ~~ :d;
spurt $cfg, qq:to/EOCONFIG/;

  # flip interpretation
  new-style = 1

  # xml prelude definitions, default is off
  [ option.xml-prelude ]
    show                = 0
    version             = 1.0
    standalone          = 'yes'

  [ option.doctype ]
    show                = 1

  [ option.doctype.entities ]
    what                = 'fun'

  [ output ]
    fileext             = 'xml'
    filename            = 'target200'
    filepath            = "$dir"

  [ output.program ]
    pdf           = 'xsltproc --encoding utf-8 %op/Xsl/ss-fo.xsl - | xep -fo - -pdf %op/Manual.pdf'
    xhtml         = 'xsltproc --encoding utf-8 --xinclude %op/Xsl/ss-xhtml.xsl - > %op/Manual.xhtml'
    chunk         = 'xsltproc --encoding utf-8 %op/Xsl/ss-chunk.xsl -'

  [ module ]
    lorem         = 'SxmlLib::LoremIpsum'

  EOCONFIG

my Str $f = "$dir/f200.sxml";
spurt $f, q:to/EOSXML/;
  $|html [
    $|body [
      $|h1 [ Burp ]
      $|p [ this is &what;! ]
    ]
  ]
  EOSXML

#-------------------------------------------------------------------------------
my SemiXML::Sxml $x;

$x .= new( :trace, :merge);
$x.parse(:filename($f));
my Str $xml-text = ~$x;
like $xml-text, /:s '<body><h1>Burp'/, 'Found a piece of xml';
$x.save;


$x.parse(:content(slurp($f)));
$xml-text = ~$x;
like $xml-text, /:s '<body><h1>Burp'/, 'Found a piece of xml';

note $xml-text;


#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink $cfg;
unlink $f;
unlink "$dir/target200.xml";
rmdir $dir;
