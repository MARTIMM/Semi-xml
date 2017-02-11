use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML;

#-------------------------------------------------------------------------------
class EPub3::Builder:ver<0.2.0> {

  constant mediatypes = %(
    :ncx<application/x-dtbncx+xml>,

    :xpgt<application/vnd.adobe-page-template+xml>,
    :css<text/css>,

    :gif<image/gif>, :jpg<image/jpg>, :jpeg<image/jpg>,
    :png<image/png>,

    :html<application/html>, :xhtml<application/xhtml+xml>,
  );

  has Hash $!doc-refs = {};
  has Int $!doc-id-count = 1;
  has Hash $!epub-attrs = {};

  has Str $!meta-dir;
  has Str $!oebps-dir;

  #-----------------------------------------------------------------------------
  method make (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

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
    $!epub-attrs = %( |%$!epub-attrs,

      :title($attrs<title> // 'No Title'),
      :creator($attrs<creator> // 'Unknown'),
      :language($attrs<language> // 'US-en'),
      :rights($attrs<rights> // 'Public Domain'),
      :publisher($attrs<publisher> // $attrs<creator> // 'Unknown'),
      :book-id($attrs<book-id> // 'Unknown should be unique book id'),
      :id-scheme($attrs<id-scheme> // 'Unknown'),

      :epub-build-dir($attrs<epub-build-dir> // '/tmp/epub3-build-dir'),
      :epub-doc-name($attrs<epub-doc-name> // {
          my Str $name = $attrs<title>;
          $name ~~ s:g/ (<[,.]>|\s)+ /-/;
        }
      ),

      :mimetype($attrs<mimetype> // 'application/epub+zip'),
      :cleanup(?$attrs<cleanup>),
      :formatted-xml(?$attrs<formatted-xml>),
    );

    my Str $build-dir = $!epub-attrs<epub-build-dir>;
    note "Check build directory $build-dir";
    mkdir( $build-dir, 0o755) unless $build-dir.IO ~~ :e;

    my Str $mimetype = $!epub-attrs<mimetype>;
    note "Store mimetype data: $mimetype";
    spurt( "$build-dir/mimetype", $mimetype);

    $!meta-dir = "$build-dir/META-INF";
    note "Check build directory $!meta-dir";
    mkdir( $!meta-dir, 0o755) unless $!meta-dir.IO ~~ :e;

    # OEBPS - Open EBook Publication Structure
    $!oebps-dir = "$build-dir/OEBPS";
    note "Check build directory $!oebps-dir";
    mkdir( $!oebps-dir, 0o755) unless $!oebps-dir.IO ~~ :e;

    my Str $images-dir = "$!oebps-dir/Images";
    note "Check build directory $images-dir";
    mkdir( $images-dir, 0o755) unless $images-dir.IO ~~ :e;

    my Str $styles-dir = "$!oebps-dir/Styles";
    note "Check build directory $styles-dir";
    mkdir( $styles-dir, 0o755) unless $styles-dir.IO ~~ :e;

    my Str $text-dir = "$!oebps-dir/Text";
    note "Check build directory $text-dir";
    mkdir( $text-dir, 0o755) unless $text-dir.IO ~~ :e;

    self!make-package($content-body);

    self!make-container;
    self!make-report($parent);
    $parent;
  }

  #-----------------------------------------------------------------------------
  # Gather the data for the manifest
  method manifest (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my XML::Element $manifest .= new(:name<manifest>);
    my Str $workdir = $attrs<workdir> // '.';
    $!epub-attrs<workdir> = $workdir;

    # Add the toc ref to it
    self!check-href('toc.ncx');
    append-element(
      $manifest, 'item',
      %( :id($!doc-refs<toc.ncx><id>), :href<toc.ncx>,
         :media-type($!doc-refs<toc.ncx><media-type>)
       )
    );

    my @items = $content-body.nodes;
    for @items -> $i {
      my Str $href = $i.attribs<href>;
      $!doc-refs{$href}<exists> = "$workdir/$href".IO ~~ :r;
      if $!doc-refs{$href}<exists> {

        append-element(
          $manifest, 'item',
          %( :id($!doc-refs{$href}<id>),
             :href("$href"),
             :media-type($!doc-refs{$href}<media-type>)
           )
        );

        # copy file as if it is binary
#        spurt( "$!oebps-dir/$href", slurp( "$workdir/$href", :bin), :bin);
#        note "File $workdir/$href copied";
      }
    }

    $parent.append($manifest);


    my XML::Element $spine .= new( :name<spine>, :attribs(%(:toc<ncx>,)));
    for @items -> $i {

      my Str $href = $i.attribs<href>;
      if $!doc-refs{$href}<exists> and $i.attribs<in-toc> {
        append-element( $spine, 'itemref', %(:idref($!doc-refs{$href}<id>),));
      }
    }

    $parent.append($spine);

    $parent;
  }

  #-----------------------------------------------------------------------------
  # Process an item
  method item (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my XML::Element $item;
    my Str $href = $attrs<href>;
    if self!check-href($href) or $!doc-refs{$href}:exists {
      $item .= new( :name<i>, :attribs( %( :$href, :in-toc(?$attrs<toc>),)));
    }

note "item: $item";
    $item;
  }

  #-----------------------------------------------------------------------------
  method !check-href ( Str $href --> Bool ) {

    my Bool $inserted = False;
    if ? $href and $!doc-refs{$href}:!exists {
      my Str $doc-id = "doc-" ~ $!doc-id-count++;
      my Str $ext = $href.IO.extension;

      $!doc-refs{$href} = %(
        :id($doc-id),
        :media-type(mediatypes{$ext} // 'application/text'),
      );

      $inserted = True;
    }

    $inserted;
  }

  #-----------------------------------------------------------------------------
  # Make report
  method !make-report ( $parent ) {

    my XML::Element $html = append-element( $parent, 'html');
    append-element( $html, 'head');
    append-element( $html, 'body');
  }

  #-----------------------------------------------------------------------------
  # Make container
  method !make-container ( ) {

    my XML::Element $container = XML::Element.new(
      :name<container>,
      :attribs( %(
          :version<1.0>,
          :xmlns<urn:oasis:names:tc:opendocument:xmlns:container>,
        )
      )
    );

    my XML::Element $rf = append-element( $container, 'rootfiles');
    append-element(
      $rf, 'rootfile', %(
        :full-path("$!oebps-dir/content.opf"),
        :media-type<application/oebps-package+xml>
      )
    );

    save-xml(
      :filename("$!meta-dir/container.xml"),
      :document($container),
      :config( %(
          option => {
            http-header => { :!show, },
            doctype => { :!show, },
            xml-prelude => {
              :show,
              :encoding<utf-8>,
              :version<1.0>,
            }
          }
        )
      ),
      :formatted($!epub-attrs<formatted-xml>)
    );

    note "Saved file $!meta-dir/container.xml";
  }

  #-----------------------------------------------------------------------------
  # Make package
  method !make-package( XML::Element $content-body) {

    my Str $unique-identifier = 'SxmlLib-EPub3-DocId';

    my XML::Element $package = XML::Element.new(
      :name<package>,
      :attribs( %(
          :version<3.1>,
          :xmlns<http://www.idpf.org/2007/opf>,
          :$unique-identifier,
        )
      )
    );

    my XML::Element $metadata = append-element(
      $package, 'metadata', %(
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
        'xmlns:opf' => 'http://www.idpf.org/2007/opf'
      )
    );

    my XML::Element $m = append-element( $metadata, 'dc:title');
    append-element( $m, :text($!epub-attrs<title>));

    $m = append-element( $metadata, 'dc:language');
    append-element( $m, :text($!epub-attrs<language>));

    $m = append-element( $metadata, 'dc:rights');
    append-element( $m, :text($!epub-attrs<rights>));

    $m = append-element( $metadata, 'dc:publisher');
    append-element( $m, :text($!epub-attrs<publisher>));

    $m = append-element(
      $metadata, 'dc:identifier',
      %( 'opf:scheme' => $!epub-attrs<id-scheme>, :id($unique-identifier))
    );
    append-element( $m, :text($!epub-attrs<book-id>));

#    $m = append-element( $metadata, 'dc:');
#    append-element( $m, :text($!epub-attrs<>));

#    $m = append-element( $metadata, 'meta', %());
#    append-element( $m, :text($!epub-attrs<>));

    # Find the manifest and spine. There is only one of each of them
    my XML::Element $manifest = $content-body.getElementsByTagName('manifest')[0];
    my Str $workdir = $!epub-attrs<workdir>;
    for $manifest.getElementsByTagName('item') -> $item {

      my Str $href = $item.attribs<href>;
      if $href ne 'toc.ncx' {
        # copy file as if it is binary
        spurt( "$!oebps-dir/$href", slurp( "$workdir/$href", :bin), :bin);
        note "File $workdir/$href copied";
      }
    }

    $package.append($manifest);
    $package.append($content-body.getElementsByTagName('spine')[0]);

    save-xml(
      :filename("$!oebps-dir/content.opf"),
      :document($package),
      :config( %(
          option => {
            http-header => { :!show, },
            doctype => { :!show, },
            xml-prelude => {
              :show,
              :encoding<utf-8>,
              :version<1.0>,
            }
          }
        )
      ),
      :formatted($!epub-attrs<formatted-xml>)
    );

    note "Saved file $!oebps-dir/content.opf";
  }
}
