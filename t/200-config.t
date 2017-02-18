use v6.c;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
my Str $d = 't/D';
mkdir $d unless $d.IO ~~ :d;
spurt "$d/SemiXML.toml", q:to/EOCONFIG/;

  # xml prelude definitions, default is off
  [ xml-prelude ]
    show                = 0
    version             = 1.0
    standalone          = 'yes'

  # on when --out=xml
  [ xml-prelude.xml ]
    show                = 1

  # on when --out=xsl
  [ xml-prelude.xsl ]
    show                = 1

  # on when file f200.sxml is used
  [ xml-prelude.f200 ]
    show                = 1

  # on when file f201.sxml is used
  [ xml-prelude.f201 ]
    show                = 0



  [ doctype ]
    show                = 1

  [ doctype.entities ]
    what                = 'fun'

  [ output ]
    fileext             = 'xml'

  [ program ]
    pdf           = 'xsltproc --encoding utf-8 %op/Xsl/ss-fo.xsl - | xep -fo - -pdf %op/Manual.pdf'
    xhtml         = 'xsltproc --encoding utf-8 --xinclude %op/Xsl/ss-xhtml.xsl - > %op/Manual.xhtml'
    chunk         = 'xsltproc --encoding utf-8 %op/Xsl/ss-chunk.xsl -'

    xml           = 'xmllint --format - > %op/%of.%oe'
    xsl           = 'xmllint --format - > %op/Xsl/%of.xsl'

    # Generate formatted xml first and save it on disk (tee command)
    # then send formatted xml to rnc for checking. This way the errors
    # can be found at the proper line in the save xml file.
    check         = 'xmllint --format - | tee %op/%of.%oe |rnv /usr/share/xml/docbook5/schema/rng/5.0/docbook.rnc'

  [ module ]
    lorem         = 'SxmlLib::LoremIpsum'
    Db5b          = 'SxmlLib::Docbook5::Basic'
    Db5f          = 'SxmlLib::Docbook5::FixedLayout'
    SxmlCore      = 'SxmlLib::SxmlCore'

  EOCONFIG



my Str $f = 't/D/f200.sxml';
spurt $f, q:to/EOSXML/;
  $|html [
    $|body [
      $|h1 [ Burp ]
      $|p [ this is &what;! ]
    ]
  ]
  EOSXML

#-------------------------------------------------------------------------------
my SemiXML::Sxml $x .= new( :trace, :merge);
$x.parse-file(:filename($f));
my Str $xml-text = ~$x;
like $xml-text, /:s '<body><h1>Burp'/, 'Found a piece of xml';

note $xml-text;

#-------------------------------------------------------------------------------
# cleanup
done-testing;


#unlink ...
