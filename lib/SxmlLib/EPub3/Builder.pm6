use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML;

#-------------------------------------------------------------------------------
class EPub3::Builder:ver<0.1.0> {

  #-----------------------------------------------------------------------------
  method make (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body
    --> XML::Node
  ) {

    my Str $build-dir = $attrs<epub-build-dir> // '/tmp/epub3-doc';
    note "Check build directory $build-dir";
    mkdir( $build-dir, 0o755) unless $build-dir.IO ~~ :e;

    my Str $mimetype = $attrs<mimetype>;
    note "Store mimetype data: $mimetype";
    spurt( "$build-dir/mimetype", $mimetype);

    my Str $meta-dir = "$build-dir/META-INF";
    note "Check build directory $meta-dir";
    mkdir( $meta-dir, 0o755) unless $meta-dir.IO ~~ :e;

    my Str $oebps-dir = "$build-dir/OEBPS";
    note "Check build directory $oebps-dir";
    mkdir( $oebps-dir, 0o755) unless $oebps-dir.IO ~~ :e;

    my Str $images-dir = "$build-dir/OEBPS/Images";
    note "Check build directory $images-dir";
    mkdir( $images-dir, 0o755) unless $images-dir.IO ~~ :e;

    my Str $styles-dir = "$build-dir/OEBPS/Styles";
    note "Check build directory $styles-dir";
    mkdir( $styles-dir, 0o755) unless $styles-dir.IO ~~ :e;

    my Str $text-dir = "$build-dir/OEBPS/Text";
    note "Check build directory $text-dir";
    mkdir( $text-dir, 0o755) unless $text-dir.IO ~~ :e;


    self!make-container( $oebps-dir, $meta-dir);
    self!report($parent);
    $parent;
  }

  #-----------------------------------------------------------------------------
  # Make report of setup
  method !report ( $parent ) {

    my XML::Element $html = append-element( $parent, 'html');
    append-element( $html, 'head');
    append-element( $html, 'body');
  }

  #-----------------------------------------------------------------------------
  # Make report of setup
  method !make-container ( Str $oebps-dir, Str $meta-dir ) {

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
        :full-path("$oebps-dir/content.opf"),
        :media-type<application/oebps-package+xml>
      )
    );

    save-xml(
      :filename("$meta-dir/container.xml"),
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
      )
    );

    note "Saved file $meta-dir/container.xml";
  }
}
