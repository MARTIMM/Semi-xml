use v6.c;

# Check sigil, pandoc, perl5 EBook::EPUB,

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use SxmlLib::EPub;

use XML;
use SemiXML;

#-------------------------------------------------------------------------------
class EPub::EPub3Builder is SxmlLib::EPub {

  has Hash $!doc-refs = {};
  has Int $!doc-id-count = 1;
#  has Hash $.epub-attrs = {};

  has Str $!meta-dir;
  has Str $!oebps-dir;

  #-----------------------------------------------------------------------------
  method make (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {
#`{{
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
    $.epub-attrs = %( |%$.epub-attrs,

      :title($attrs<title> // 'No Title'),
      :creator($attrs<creator> // 'Unknown'),
      :language($attrs<language> // 'US-en'),
      :rights($attrs<rights> // 'Public Domain'),
      :publisher($attrs<publisher> // $attrs<creator> // 'Unknown'),
      :book-id($attrs<book-id> // 'Unknown should be unique book id'),
      :id-type($attrs<book-id-type> // 'Unknown'),
#version 2
#      :nav-doc<toc.ncx>,
      :nav-doc($attrs<nav-doc> // 'navigation.xhtml'),

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
}}
    self.set-epub-attrs( 'epub3', $attrs);

    my Str $build-dir = $.epub-attrs<epub-build-dir>;
    note "Check build directory $build-dir";
    mkdir( $build-dir, 0o755) unless $build-dir.IO ~~ :e;

    my Str $mimetype = $.epub-attrs<mimetype>;
    note "Create mimetype file for '$mimetype'";
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

    self!make-container;
    self!make-package($content-body);
    self!make-nav($content-body);
    self!make-report($parent);
    self.make-epub;
    self.cleanup;

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
    $.epub-attrs<workdir> = $workdir;

    # Add the toc ref to it. Name not yet known, so make something up
    my Str $nav-doc = 'NAV-DOC-PLACEHOLDER-NAME';
    self!check-href($nav-doc);
    append-element(
      $manifest, 'item',
      %( :id($!doc-refs{$nav-doc}<id>), :href($nav-doc),
         :media-type($!doc-refs{$nav-doc}<media-type>),
         :properties<nav>
       )
    );

    my @items = $content-body.nodes;
    for @items -> $i {
      my Str $href = $i.attribs<href>;
      $!doc-refs{$href}<exists> = "$workdir/$href".IO ~~ :r;
      if $!doc-refs{$href}<exists> {

        my XML::Element $item = append-element(
          $manifest, 'item',
          %( :id($!doc-refs{$href}<id>),
             :href("$href"),
             :media-type($!doc-refs{$href}<media-type>)
           )
        );
        $item.set( 'properties', $!doc-refs{$href}<properties>)
          if ? $!doc-refs{$href}<properties>;

        # copy file as if it is binary
#        spurt( "$!oebps-dir/$href", slurp( "$workdir/$href", :bin), :bin);
#        note "File $workdir/$href copied";
      }
    }

    $parent.append($manifest);

#TODO compatibility version < 3    :attribs(%(:toc<ncx>

    my XML::Element $spine .= new(:name<spine>);
    for @items -> $i {

      my Str $href = $i.attribs<href>;
      if $!doc-refs{$href}<exists> and $i.attribs<spine> {
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
    if $!doc-refs{$href}:exists
       or self!check-href( $href, :prop($attrs<properties> // '')) {
      $item .= new( :name<i>, :attribs( %( :$href, :spine(?$attrs<spine>),)));
    }

    $item;
  }

  #-----------------------------------------------------------------------------
  # Process an item
  method navigation (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

     my XML::Element $hook .= new(:name<hook>);
     my XML::Element $nav .= new( :name<navigation>);

     $nav.append($hook);
     for @($content-body.nodes).reverse -> $node {
       $hook.after($node);
     }

     $hook.remove;

     $nav;
  }

  #-----------------------------------------------------------------------------
  method !check-href ( Str $href, Str :$prop --> Bool ) {

    my Bool $inserted = False;
    if ? $href and $!doc-refs{$href}:!exists {
      my Str $doc-id = "doc-" ~ $!doc-id-count++;
      my Str $ext = $href.IO.extension;

      $!doc-refs{$href} = %(
        :id($doc-id),
        :media-type(mediatypes{$ext} // 'application/text'),
      );
      $!doc-refs{$href}<properties> = $prop if ?$prop;

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
    my Str $path = "$!oebps-dir/package.opf";
    my Str $builddir = $.epub-attrs<epub-build-dir>;
    $path ~~ s/ $builddir '/'//;
    append-element(
      $rf, 'rootfile', %(
        :full-path($path),
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
      :formatted($.epub-attrs<formatted-xml>)
    );

    note "Create file $!meta-dir/container.xml";
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
    append-element( $m, :text($.epub-attrs<title>));

    $m = append-element( $metadata, 'dc:language');
    append-element( $m, :text($.epub-attrs<language>));

    $m = append-element( $metadata, 'dc:rights');
    append-element( $m, :text($.epub-attrs<rights>));

    $m = append-element( $metadata, 'dc:publisher');
    append-element( $m, :text($.epub-attrs<publisher>));

#`{{
    # Version 2 compat
    $m = append-element(
      $metadata, 'dc:identifier',
      %( 'opf:scheme' => $.epub-attrs<id-type>, :id($unique-identifier))
    );
    append-element( $m, :text($.epub-attrs<book-id>));
}}
    $m = append-element(
      $metadata, 'dc:identifier', %(:id($unique-identifier,))
    );
    append-element(
      $m, :text('urn:' ~ $.epub-attrs<id-type> ~ ':' ~ $.epub-attrs<book-id>)
    );

    # version 3
    $m = append-element( $metadata, 'meta', %(:property<dcterms:modified>,));
    append-element( $m, :text(DateTime.now.utc.Str) );

#    $m = append-element( $metadata, 'dc:');
#    append-element( $m, :text($.epub-attrs<>));

#    $m = append-element( $metadata, 'meta', %());
#    append-element( $m, :text($.epub-attrs<>));

    # Find the manifest and spine. There is only one of each of them
    my XML::Element $manifest = $content-body.getElementsByTagName('manifest')[0];
    my Str $workdir = $.epub-attrs<workdir>;
    my Str $nav-doc = $.epub-attrs<nav-doc>;
    for $manifest.getElementsByTagName('item') -> $item {

      my Str $href = $item.attribs<href>;

      # Could not save the real name in manifest. Now it is known it can be
      # replaced by the real name.
      if $href eq 'NAV-DOC-PLACEHOLDER-NAME' {
        $item.set( 'href', $nav-doc);
        $!doc-refs{$nav-doc} = $!doc-refs{'NAV-DOC-PLACEHOLDER-NAME'};
        $!doc-refs{'NAV-DOC-PLACEHOLDER-NAME'}:delete;

        # It's going to be ...
        $!doc-refs{$nav-doc}<exists> = True;
      }

      else {
        # copy file as if it is binary
        spurt( "$!oebps-dir/$href", slurp( "$workdir/$href", :bin), :bin);
        note "File $workdir/$href copied";
      }
    }

    $package.append($manifest);

    # Must clone it, because we need it also later in the navigation
    $package.append($content-body.getElementsByTagName('spine')[0].cloneNode);

    save-xml(
      :filename("$!oebps-dir/package.opf"),
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
      :formatted($.epub-attrs<formatted-xml>)
    );

    note "Create file $!oebps-dir/content.opf";
  }

  #-----------------------------------------------------------------------------
  method !make-nav ( XML::Element $content-body ) {

    my XML::Element $nav-html .= new(
      :name<html>,
      :attribs( %(
          :xmlns<http://www.w3.org/1999/xhtml>,
          'xmlns:epub' => 'http://www.idpf.org/2007/ops',
        )
      )
    );

    my Array $nav-array =
       $content-body.getElementsByTagName('navigation') // [XML::Element];

    if $nav-array.elems {

      $nav-html.append($nav-array[0]);
    }

    else {

      my XML::Element $head = append-element( $nav-html, 'head');
      append-element( $head, 'title', :text($.epub-attrs<title>));

      my XML::Element $body = append-element( $nav-html, 'body');
      my XML::Element $nav = append-element(
        $body, 'nav', %('epub:type' => 'toc', :id<toc>)
      );

      append-element( $nav, 'h1', :text($.epub-attrs<title>));
      my XML::Element $ol = append-element( $nav, 'ol');

      my XML::Element $spine = $content-body.getElementsByTagName('spine')[0];
      my Array $spine-items = $spine.getElementsByTagName('itemref');

      my Int $count = 1;
      for @$spine-items -> $si {
        my Str $href;
        for $!doc-refs.keys -> $h {
          if $si.attribs<idref> eq $!doc-refs{$h}<id> {
            $href = $h;
            last;
          }
        }

        my $ref-name = $href.IO.basename;
        $ref-name ~~ s/ '.' <-[\.]>+ $//;
        my XML::Element $li = append-element( $ol, 'li');
        append-element(
          $li, 'a', %(:$href), :text("Part {$count++} - $ref-name")
        );
      }
    }

    save-xml(
      :filename("$!oebps-dir/$.epub-attrs<nav-doc>"),
      :document($nav-html),
      :config( %(
          option => {
            http-header => { :!show, },
            doctype => { :show, },
            xml-prelude => {
              :show,
              :encoding<utf-8>,
              :version<1.0>,
            }
          }
        )
      ),
      :formatted($.epub-attrs<formatted-xml>)
    );

    note "Create file $!oebps-dir/toc.xhtml";
  }
}
