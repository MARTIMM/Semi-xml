use v6;

# Check sigil, pandoc, perl5 EBook::EPUB,

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use XML;
#use SemiXML::Sxml;
use SxmlLib::SxmlHelper;

#-------------------------------------------------------------------------------
#TODO compatibility with version2 NCX navigation documents?

class EPub:ver<0.4.1> {

  constant mediatypes is export = %(
    :ncx<application/x-dtbncx+xml>,

    :xpgt<application/vnd.adobe-page-template+xml>,
    :css<text/css>,

    :js<text/javascript>,

    :gif<image/gif>, :jpg<image/jpeg>, :jpeg<image/jpeg>,
    :png<image/png>, :svg<image/svg+xml>,

    :html<application/html>, :xhtml<application/xhtml+xml>,
  );

  has Hash $.epub-attrs is rw = {};

  #-----------------------------------------------------------------------------
  method set-epub-attrs ( Str $version, Hash $attrs ) {

    # The first item is workdir and is inserted by manifest(). So to
    # add other items, slip the epub attributes in first.
    #
    # Attributes
    #   epub-build-dir          default '/tmp/epub3-build-dir'
    #   epub-doc-name           default from title
    #   cleanup                 default 1
    #   formatted-xml           default 1, needs xmllint
    #   mimetype                default 'application/epub+zip'
    #   publisher               default from creator
    #   nav-doc                 default 'navigation.xhtml'
    $!epub-attrs = %( |%$!epub-attrs,

      :title(~$attrs<title> // 'No Title'),
      :creator(~$attrs<creator> // 'Unknown'),
      :language(~$attrs<language> // 'US-en'),
      :rights(~$attrs<rights> // 'Public Domain'),
      :publisher(~$attrs<publisher> // ~$attrs<creator> // 'Unknown'),
      :book-id(~$attrs<book-id> // 'Unknown should be unique book id'),
      :id-type(~$attrs<book-id-type> // 'Unknown'),

      :epub-build-dir(~$attrs<epub-build-dir> // '/tmp/epub3-build-dir'),
      :epub-doc-name(~$attrs<epub-doc-name> // {
          my Str $name = ~$attrs<title>;
          $name ~~ s:g/ (<[,.]>|\s)+ /-/;
        }
      ),

      :mimetype(~$attrs<mimetype> // 'application/epub+zip'),
      :cleanup(? ~$attrs<cleanup>),
      :formatted-xml(? ~$attrs<formatted-xml>),
    );

    if $version eq 'epub3' {
      $!epub-attrs<nav-doc> = ~($attrs<nav-doc> // 'navigation.xhtml')
    }

    else { # epub2
      $!epub-attrs<nav-doc> = 'toc.ncx';
    }
  }

  #-----------------------------------------------------------------------------
  method make-epub ( ) {

    my $cwd = $*CWD;
    chdir($!epub-attrs<epub-build-dir>);

    shell "zip -Z store ../$!epub-attrs<epub-doc-name>.epub mimetype";
    shell "zip -r -Z deflate ../$!epub-attrs<epub-doc-name>.epub META-INF";
    shell "zip -r -Z deflate ../$!epub-attrs<epub-doc-name>.epub OEBPS";

    chdir($cwd);
  }

  #-----------------------------------------------------------------------------
  method cleanup ( ) {

  }
}
