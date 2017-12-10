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
    :message("empty map-to value");
}

#-------------------------------------------------------------------------------
sub get-xpath ( Str $content --> XML::XPath ) {

  my SemiXML::Sxml $x .= new;
  $x.parse(
    config => {
      ML => {
        :colors<SxmlLib::Colors>,
        :css<SxmlLib::Css>,
      }
    },
    :$content
  );

  # See the result
  my Str $xml-text = ~$x;
  diag $xml-text;

  XML::XPath.new(:xml($xml-text))
}

#-------------------------------------------------------------------------------
done-testing;
