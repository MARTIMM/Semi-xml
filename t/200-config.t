use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
my Str $dir = 't/D200';
my Str $cfg = "$dir/SemiXML.toml";
mkdir $dir unless $dir.IO ~~ :d;
spurt $cfg, qq:to/EOCONFIG/;

  #--[new config]-----------------------------------------------------------------
  # Defaults
  [ D ]
    xml-show              = false
    xml-version           = '1.0'
    xml-encoding          = 'UTF-8'
  #  xml-standalone        = 'yes'
    doctype-show          = false
    http-show             = false

  #  filename              = 'default basename of sxml file'
  #  filepath              = 'default path of sxml file'
  #  fileext               = 'xml'

  #[ D.Libraries ]
  #  SxmlCore              = 'lib'

  [ D.Modules ]
    SxmlCore              = 'SxmlLib::SxmlCore'

  [ D.Entities ]
    copy                  = '&#xa9;'

  # sxml2xml use
  #[ D.Dependencies ]



  # in = xml, out = xml
  [ D.xml.xml ]
    xml-show              = true
    doctype-show          = true

  #[ D.Run.xml ]
  #  xml                   = 'xmllint --format - > %op/%of.%oe'

  [ D.Run.xml ]
    check                 = 'xmllint --format - > %op/%of.%oe'
    xsl                   = 'xmllint --format - > %op/Xsl/%of.xsl'

  [ D.http.email ]
    Content-Type          = 'text/html; charset="utf-8"'
    From                  = 'my-addr@gmail.com'
    User-Agent            = 'SemiXML'



  # Example document is html
  [ D.html ]
    inline                = [ 'b', 'i', 'strong']
    non-nesting           = [ 'script', 'style']
    space-preserve        = [ 'pre' ]

    xml-show              = true
    doctype-show          = true

  [ D.Modules.html ]
    lorem                 = 'SxmlLib::LoremIpsum'



  [ D.db5 ]
    inline                = [ 'emphasis']
    space-preserve        = [ 'programlisting']
    xml-show              = true
    doctype-show          = true

  [ D.db5.pdf ]
    run                   = 'xsltproc --encoding utf-8 %op/Xsl/ss-fo.xsl - | xep -fo - -pdf %op/Manual.pdf'

  [ D.db5.xhtml ]
    run                   = 'xsltproc --encoding utf-8 --xinclude %op/Xsl/ss-xhtml.xsl - > %op/Manual.xhtml'

  [ R.db5.chunk ]
    chunk                 = 'xsltproc --encoding utf-8 %op/Xsl/ss-chunk.xsl -'

  [ M.db5 ]
    lorem                 = 'SxmlLib::LoremIpsum'
    Db5b                  = 'SxmlLib::Docbook5::Basic'
    Db5f                  = 'SxmlLib::Docbook5::FixedLayout'

  [ E.db5 ]
    copy                  = '&#xa9;'
    nbsp                  = ' '

  EOCONFIG

my Str $f = "$dir/f200.sxml";
spurt $f, q:to/EOSXML/;
  $html [
    $body [
      $h1 [ Burp ]
      $p [ this is &what;! ]
    ]
  ]
  EOSXML

#-------------------------------------------------------------------------------
my SemiXML::Sxml $x;

#is 1,1,'yes';
#done-testing;
#exit;

$x .= new( :trace, :merge, :refine([ <db5>]));
$x.parse(:filename($f));
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
