use v6.c;

use SemiXML;

# Package cannot be placed in SemiXML/Lib and named File.pm6. Evaluation seems
# to fail not finding the symbol &File when doing so.
#
unit package SxmlLib:auth<https://github.com/MARTIMM>;

class Docbook5::Basic {
  has Hash $.symbols = {

    # $.m.book []
    #
    book => {
      tag-name => 'book',
      attributes => {
        'xmlns' => 'http://docbook.org/ns/docbook',
        'xmlns:xi' => 'http://www.w3.org/2001/XInclude',
        'xmlns:xl' => 'http://www.w3.org/1999/xlink',
        'version' => '5.0',
        'xml:lang' => 'en'
      }
    },

    # $.m.article []
    #
    article => {
      tag-name => 'article',
      attributes => {
        'xmlns' => 'http://docbook.org/ns/docbook',
        'xmlns:xi' => 'http://www.w3.org/2001/XInclude',
        'xmlns:xl' => 'http://www.w3.org/1999/xlink',
        'version' => '5.0',
        'xml:lang' => 'en'
      }
    },
  };

  #-----------------------------------------------------------------------------
  method Xarticle ( XML::Element $parent,
                   Hash $attrs is copy,
                   XML::Node :$content-body
                 ) {

  }

  #-----------------------------------------------------------------------------
  # $!m.info attributes [ content ]
  # Attributes
  #   firstname, surname, email,
  #   addr-city, addr-country,
  #   copy-year, copy-holder
  # Content
  #   $para [] blocks used to describe abstract
  #
  method info ( XML::Element $parent,
                Hash $attrs is copy,
                XML::Element :$content-body
              ) {

    my $firstname = $attrs<firstname>;
    my $surname = $attrs<surname>;
    my $email = $attrs<email>;

    my XML::Element $info = append-element( $parent, 'info');

    if $firstname.defined or $surname.defined or $email.defined {
      my XML::Element $author = append-element( $info, 'author');

      if $firstname.defined or $surname.defined {
        my XML::Element $personname = append-element( $author, 'personname');

        if $firstname.defined {
          my XML::Element $f = append-element( $personname, 'firstname');
          $f.append(XML::Text.new(:text($firstname)));
        }

        if $surname.defined {
          my XML::Element $s = append-element( $personname, 'surname');
          $s.append(XML::Text.new(:text($surname)));
        }
      }
    }

    my $city = $attrs<city>;
    my $country = $attrs<country>;
    my $ = $attrs<>;
    if $city.defined or $country.defined {

      my XML::Element $address = append-element( $info, 'address');
      if $city.defined {
        my XML::Element $c = append-element( $address, 'city');
        $c.append(XML::Text.new(:text($city)));
      }

      if $country.defined {
        my XML::Element $c = append-element( $address, 'country');
        $c.append(XML::Text.new(:text($country)));
      }
    }

    my $copy-year = $attrs<copy-year>;
    my $copy-holder = $attrs<copy-holder>;
    if $copy-year.defined or $copy-holder.defined {
      my XML::Element $copyright = append-element( $info, 'copyright');

      if $copy-year.defined {
        my XML::Element $c = append-element( $copyright, 'year');
        $c.append(XML::Text.new(:text($copy-year)));
      }

      if $copy-holder.defined {
        my XML::Element $c = append-element( $copyright, 'holder');
        $c.append(XML::Text.new(:text($copy-holder)));
      }
    }

    my XML::Element $date = append-element( $info, 'date');
    $date.append(XML::Text.new(:text(Date.today().Str)));

    my XML::Element $abstract = append-element( $info, 'abstract');
    $abstract.insert($_) for $content-body.nodes.reverse;

    $parent;
  }
}

