use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Element;

#-------------------------------------------------------------------------------
class Docbook5::Basic:ver<0.3.2> {

  #-----------------------------------------------------------------------------
  method book ( SemiXML::Element $m ) {

    my SemiXML::Element $art .= new(
      :name<book>,
      :attributes( {
          'xmlns' => 'http://docbook.org/ns/docbook',
          'xmlns:xi' => 'http://www.w3.org/2001/XInclude',
          'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
          'version' => '5.0',
          'xml:lang' => 'en'
        }
      )
    );

    $m.before($art);
    $art.insert($_) for $m.nodes.reverse;
  }

  #-----------------------------------------------------------------------------
  method article ( SemiXML::Element $m ) {

    my SemiXML::Element $art .= new(
      :name<article>,
      :attributes( {
          'xmlns' => 'http://docbook.org/ns/docbook',
          'xmlns:xi' => 'http://www.w3.org/2001/XInclude',
          'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
          'version' => '5.0',
          'xml:lang' => 'en'
        }
      )
    );

    $m.before($art);
    $art.insert($_) for $m.nodes.reverse;
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
  method info ( SemiXML::Element $m ) {

    my $firstname = $m.attributes<firstname>.Str;
    my $surname = $m.attributes<surname>.Str;
    my $email = $m.attributes<email>.Str;

    my SemiXML::Element $info .= new(:name<info>);
    $m.before($info);

    if ?$firstname or ?$surname or ?$email {
      my SemiXML::Element $author = $info.append('author');

      if ?$firstname or ?$surname {
        my SemiXML::Element $personname = $author.append('personname');
        $personname.append( 'firstname', :text($firstname)) if ?$firstname;
        $personname.append( 'surname', :text($surname)) if ?$surname;
      }

      if ?$email {
        $author.append( 'email', :text($email));
      }
    }

    my $city = $m.attributes<city>.Str;
    my $country = $m.attributes<country>.Str;
#    my $ = $m.attributes<>.Str;
    if $city.defined or $country.defined {
      my SemiXML::Element $address = $info.append('address');
      $address.append( 'city', :text($city)) if $city.defined;
      $address.append( 'country', :text($country)) if $country.defined;
    }

    my $copy-year = $m.attributes<copy-year>.Str;
    my $copy-holder = $m.attributes<copy-holder>.Str;
    if $copy-year.defined or $copy-holder.defined {
      my SemiXML::Element $copyright = $info.append('copyright');
      $copyright.append( 'year', :text($copy-year)) if $copy-year.defined;
      $copyright.append( 'holder', :text($copy-holder)) if $copy-holder.defined;
    }

    $info.append( 'date', :text(Date.today().Str));

    my SemiXML::Element $abstract = $info.append('abstract');
    $abstract.insert($_) for $m.nodes.reverse;
  }
}
