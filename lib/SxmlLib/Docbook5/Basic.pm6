use v6;

#BEGIN {
#  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
#}

use Semi-xml;
use XML;

# Package cannot be placed in Semi-xml/Lib and named File.pm6. Evaluation seems
# to fail not finding the symbol &File when doing so.
#
package SxmlLib:auth<https://github.com/MARTIMM> {

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

    #---------------------------------------------------------------------------
    #
    method Xarticle ( XML::Element $parent,
                     Hash $attrs is copy,
                     XML::Node :$content-body
                   ) {

    }

    #---------------------------------------------------------------------------
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
                  XML::Node :$content-body
                ) {

      my $firstname = $attrs<firstname>;
      my $surname = $attrs<surname>;
      my $email = $attrs<email>;

      my $info = XML::Element.new(:name('info'));
      $parent.append($info);

      if $firstname.defined or $surname.defined or $email.defined {
        my $author = XML::Element.new(:name('author'));
        $info.append($author);

        if $firstname.defined or $surname.defined {
          my $personname = XML::Element.new(:name('personname'));
          $author.append($personname);

          if $firstname.defined {
            my $f = XML::Element.new(:name('firstname'));
            $personname.append($f);
            $f.append(XML::Text.new(:text($firstname)));
          }

          if $surname.defined {
            my $s = XML::Element.new(:name('surname'));
            $personname.append($s);
            $s.append(XML::Text.new(:text($surname)));
          }
        }
      }

      my $city = $attrs<city>;
      my $country = $attrs<country>;
      my $ = $attrs<>;
      if $city.defined or $country.defined {
        my $address = XML::Element.new(:name('address'));
        $info.append($address);

        if $city.defined {
          my $c = XML::Element.new(:name('city'));
          $address.append($c);
          $c.append(XML::Text.new(:text($city)));
        }

        if $country.defined {
          my $c = XML::Element.new(:name('country'));
          $address.append($c);
          $c.append(XML::Text.new(:text($country)));
        }
      }

      my $copy-year = $attrs<copy-year>;
      my $copy-holder = $attrs<copy-holder>;
      if $copy-year.defined or $copy-holder.defined {
        my $copyright = XML::Element.new(:name('copyright'));
        $info.append($copyright);

        if $copy-year.defined {
          my $c = XML::Element.new(:name('year'));
          $copyright.append($c);
          $c.append(XML::Text.new(:text($copy-year)));
        }

        if $copy-holder.defined {
          my $c = XML::Element.new(:name('holder'));
          $copyright.append($c);
          $c.append(XML::Text.new(:text($copy-holder)));
        }
      }

      my $date = XML::Element.new(:name('date'));
      $info.append($date);
      $date.append(XML::Text.new(:text(Date.today().Str)));

      my $abstract = XML::Element.new(:name('abstract'));
      $info.append($abstract);
      $abstract.append($_) for $content-body.nodes;
      $content-body.remove;
    }
  }
}

