use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
my Str $dir = 't/D200';
my Str $cfg = "$dir/SemiXML.toml";
mkdir $dir unless $dir.IO ~~ :d;
spurt $cfg, qq:to/EOCONFIG/;

  # Content tables --------------------------------------------------------------
  [ C ]
  xml-show              = false
  xml-version           = '1.0'
  xml-encoding          = 'UTF-8'
  #  xml-standalone        = 'yes'
  #  doctype-show          = false
  #  http-show             = false

  # out = xml
  #[ C.xml ]
  #  xml-show              = true
  #  doctype-show          = true

  # out = html
  #[ C.html ]
  #  inline                = [ 'b', 'i', 'strong']
  #  non-nesting           = [ 'script', 'style']
  #  space-preserve        = [ 'pre' ]
  #  xml-show              = true
  #  doctype-show          = true

  # out = db5 (for docbook5)
  #[ C.db5 ]
  #  inline                = [ 'emphasis']
  #  space-preserve        = [ 'programlisting']
  #  xml-show              = true
  #  doctype-show          = true

  # Dependency tables --------------------------------------------------------
  [ D ]

  # Entity tables --------------------------------------------------------------
  [ DT ]
    copy                  = '&#xa9;'

  # out = db5 (for docbook5)
  [ DT.db5 ]
    copy                  = '&#xa9;'
    nbsp                  = ' '

  # Http tables ----------------------------------------------------------------
  [ H ]

  # out = email
  [ H.email ]
    Content-Type          = 'text/html; charset="utf-8"'
    From                  = 'my-addr@gmail.com'
    User-Agent            = 'SemiXML'

  # Module tables --------------------------------------------------------------
  [ ML ]
    SxmlCore              = 'SxmlLib::SxmlCore'

  # in = email
  [ ML.html ]
    lorem                 = 'SxmlLib::LoremIpsum'

  # in = db5
  [ ML.db5 ]
    lorem                 = 'SxmlLib::LoremIpsum'
    Db5b                  = 'SxmlLib::Docbook5::Basic'
    Db5f                  = 'SxmlLib::Docbook5::FixedLayout'

  # Run tables -----------------------------------------------------------------
  [ R ]
    check                 = 'xmllint --format - > %op/%of.%oe'
    xsl                   = 'xmllint --format - > %op/Xsl/%of.xsl'

  # in = db5
  [ R.db5 ]
    pdf                   = 'xsltproc --encoding utf-8 %op/Xsl/ss-fo.xsl - | xep -fo - -pdf %op/Manual.pdf'
    xhtml                 = 'xsltproc --encoding utf-8 --xinclude %op/Xsl/ss-xhtml.xsl - > %op/Manual.xhtml'
    chunk                 = 'xsltproc --encoding utf-8 %op/Xsl/ss-chunk.xsl -'

  # Storage tables -------------------------------------------------------------
  [ S ]
  #  filename              = 'default is basename of sxml file'
  #  filepath              = 'default is path of sxml file'
    fileext               = 'xml'

  EOCONFIG

my Str $f = "$dir/f200.sxml";
spurt $f, q:to/EOSXML/;
  $html [
    $body [
      $h1 [ Burping at $!SxmlCore.date-time utc=0 iso=0 ]
      $p [ this is &what;! ]
    ]
  ]
  EOSXML

#-------------------------------------------------------------------------------
my SemiXML::Sxml $x;

#is 1,1,'yes';
#done-testing;
#exit;

$x .= new( :trace, :merge, :refine([ <db5 pdf>]));
isa-ok $x, 'SemiXML::Sxml';

$x.parse(:filename($f));

done-testing;
exit;

my Str $xml-text = ~$x;
note $xml-text;
like $xml-text, /:s '<body><h1>Burp'/, 'Found a piece of xml';
$x.save;


#$x.parse(:content(slurp($f)));
#$xml-text = ~$x;
#like $xml-text, /:s '<body><h1>Burp'/, 'Found a piece of xml';

#note $xml-text;


#-------------------------------------------------------------------------------
# cleanup
done-testing;

#unlink $cfg;
#unlink $f;
#unlink "$dir/target200.xml";
#rmdir $dir;
