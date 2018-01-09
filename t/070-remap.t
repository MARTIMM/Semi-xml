use v6;
use Test;

use SemiXML::Sxml;
use XML::XPath;

#-------------------------------------------------------------------------------
subtest 'remap parts with map-to only', {
  my Str $text = Q:to/EOXML/;
    $x [
      $y

      $z [
        $loc1 [
          $sxml:remap map-to=/x/y [
            some data and an element $abc []
          ]
        ]
      ]
    ]

    EOXML

  my XML::XPath $x = get-xpath($text);
  is $x.find( '/x/y/text()', :to-list)[0].text,
     'some data and an element', 'found text on new location';
  is $x.find( '/x/y/abc', :to-list)[0],
     '<abc/>', 'found element on new location';
}

#-------------------------------------------------------------------------------
subtest 'remap parts with map-to and as', {
  my Str $text = Q:to/EOXML/;
    $x [
      $y

      $z [
        $loc1 [
          $sxml:remap map-to=/x/y as=loc2 [
            some data and an element $abc []
          ]
        ]
      ]
    ]

    EOXML

  my XML::XPath $x = get-xpath($text);
  is $x.find( '/x/y/loc2/text()', :to-list)[0].text,
     'some data and an element', 'found text on new location';
  is $x.find( '/x/y/loc2/abc', :to-list)[0],
     '<abc/>', 'found element on new location';
}

#-------------------------------------------------------------------------------
subtest 'map-to path not found', {
  my Str $text = Q:to/EOXML/;
    $x [
      $y

      $z [
        $loc1 [
          $sxml:remap map-to=/x/y/z as=loc2 [
            some data and an element $abc []
          ]
        ]
      ]
    ]

    EOXML

  throws-like {
      my XML::XPath $x = get-xpath($text);
    }, Exception,
    'Path map-to not found',
    :message("node '/x/y/z' to map to, not found");
}

#-------------------------------------------------------------------------------
subtest 'empty map-to path', {
  my Str $text = Q:to/EOXML/;
    $x [
      $y

      $z [
        $loc1 [
          $sxml:remap [
            some data and an element $abc []
          ]
        ]
      ]
    ]

    EOXML

  throws-like {
      my XML::XPath $x = get-xpath($text);
    }, Exception,
    'No map-to found',
    :message("empty map-to or map-after value");
}

#-------------------------------------------------------------------------------
subtest 'closing / no self closing', {
  my Str $text = Q:to/EOXML/;
    $x [
      $abc
      $def
      $y [
        $sxml:remap map-to=/x/z1 [ $abc ]
        $sxml:remap map-to=/x/z2 [ $def ]
      ]
      $z1
      $z2
    ]
    EOXML

  my Str $xml-text = get-text($text);
  diag $xml-text;
  like $xml-text, /'<x><abc/><def></def>'/, 'abc self close, def is not';
  like $xml-text, /'<z1><abc/></z1>'/, 'abc self close, after remap';
  like $xml-text, /'<z2><def></def></z2>'/, 'def not self closing after remap';
  like $xml-text, /'<y/><z1>'/, 'y is now empty';
}

#-------------------------------------------------------------------------------
sub get-xpath ( Str $content --> XML::XPath ) {

  my SemiXML::Sxml $x .= new;
  $x.parse(:$content);

  # see the result
  my Str $xml-text = ~$x;
  #diag $xml-text;

  XML::XPath.new(:xml($xml-text))
}

#-------------------------------------------------------------------------------
sub get-text ( Str $content --> Str ) {

  my SemiXML::Sxml $x .= new;
  $x.parse(
    config => {
      C => {
        xml => { :!xml-show }
      },
      F => {
        self-closing => [<abc y>],
      },
    },
    :$content
  );

  # return result
  ~$x
}

#-------------------------------------------------------------------------------
done-testing;
