use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use XML;
use SemiXML;

#-------------------------------------------------------------------------------
class Docbook5::Basic:ver<0.3.0> {

  #-----------------------------------------------------------------------------
  method book (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body
    --> XML::Node
  ) {

    my XML::Element $art = append-element(
      $parent, 'book', {
        'xmlns' => 'http://docbook.org/ns/docbook',
        'xmlns:xi' => 'http://www.w3.org/2001/XInclude',
        'xmlns:xl' => 'http://www.w3.org/1999/xlink',
        'version' => '5.0',
        'xml:lang' => 'en'
      }
    );

    $art.append($content-body);
    $parent;
  }

  #-----------------------------------------------------------------------------
  method article (
    XML::Element $parent,
    Hash $attrs,
    XML::Node :$content-body
    --> XML::Node
  ) {

    my XML::Element $art = append-element(
      $parent, 'article', {
        'xmlns' => 'http://docbook.org/ns/docbook',
        'xmlns:xi' => 'http://www.w3.org/2001/XInclude',
        'xmlns:xl' => 'http://www.w3.org/1999/xlink',
        'version' => '5.0',
        'xml:lang' => 'en'
      }
    );

    $art.append($content-body);
    $parent;
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
  method info (
    XML::Element $parent,
    Hash $attrs is copy,
    XML::Element :$content-body
  ) {

    my $firstname = $attrs<firstname>;
    my $surname = $attrs<surname>;
    my $email = $attrs<email>;

    my XML::Element $info = append-element( $parent, 'info');

    if ?$firstname or ?$surname or ?$email {
      my XML::Element $author = append-element( $info, 'author');

      if ?$firstname or ?$surname {
        my XML::Element $personname = append-element( $author, 'personname');

        if ?$firstname {
          my XML::Element $f = append-element( $personname, 'firstname');
          append-element( $f, :text($firstname));
        }

        if ?$surname {
          my XML::Element $s = append-element( $personname, 'surname');
          append-element( $s, :text($surname));
        }
      }

      if ?$email {
        my XML::Element $e = append-element( $author, 'email');
        append-element( $e, :text($email));
      }
    }

    my $city = $attrs<city>;
    my $country = $attrs<country>;
#    my $ = $attrs<>;
    if $city.defined or $country.defined {

      my XML::Element $address = append-element( $info, 'address');
      if $city.defined {
        my XML::Element $c = append-element( $address, 'city');
        append-element( $c, :text($city));
      }

      if $country.defined {
        my XML::Element $c = append-element( $address, 'country');
        append-element( $c, :text($country));
      }
    }

    my $copy-year = $attrs<copy-year>;
    my $copy-holder = $attrs<copy-holder>;
    if $copy-year.defined or $copy-holder.defined {
      my XML::Element $copyright = append-element( $info, 'copyright');

      if $copy-year.defined {
        my XML::Element $c = append-element( $copyright, 'year');
        append-element( $c, :text($copy-year));
      }

      if $copy-holder.defined {
        my XML::Element $c = append-element( $copyright, 'holder');
        append-element( $c, :text($copy-holder));
      }
    }

    my XML::Element $date = append-element( $info, 'date');
    append-element( $date, :text(Date.today().Str));

    my XML::Element $abstract = append-element( $info, 'abstract');
    $abstract.insert($_) for $content-body.nodes.reverse;

    $parent;
  }
}

