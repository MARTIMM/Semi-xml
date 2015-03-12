use v6;

BEGIN {
  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
}

use Semi-xml;
use XML;

# Package cannot be placed in Semi-xml/Lib and named File.pm6. Evaluation seems
# to fail not finding the symbol &File when doing so.
#
package SxmlLib {

  class File {
    has Hash $.symbols = {};

    has Hash $.methods = {
      include => method ( XML::Element $parent, Hash $attrs ) {
        my $type = $attrs<type> // 'reference';
        my $reference = $attrs<reference> // '';
        my $document;
        given $type {
          when 'reference' {

          }

          when 'include' {

            # Check if readable
            #
            if $reference.IO ~~ :r {

              # Read the content
              #
              my $sxml-text = slurp($reference);

              # Create the parser object and parse its content. Important to
              # encapsulate the content in another tag because parsing will
              # fail if thare are more than one top level elements.
              #
              my Semi-xml $x .= new;
              $x.parse(:content("\$XX-XX-XX\[$sxml-text\]"));

              # Replace all elements below the container tag XX-XX-XX
              # in the parent element of the container.
              #
              for $parent.nodes -> $node {
                if $node.name eq 'XX-XX-XX' {
                  for $node.nodes -> $x-node {
                    $parent.append($x-node);
                  }

                  $node.remove;
                  last;
                }
              }

#                $document = $x.actions.xml-document.root;
#                say "D: ", $document, "\n" ~ $x;

#    my $grammar = Semi-xml::Grammar.new;
#    my $actions = Semi-xml::Actions.new();
#say "P1a: ", $actions;
#    my $sts = $grammar.parse( "\$X\[$sxml-text\]", :actions($actions));
#say "P2a: ", $sts ?? 'OK' !! 'NOK';
            }

            else {
              say "Reference '$reference' not found";
            }
          }

          default {
            say "Type $type not recognized with \$!include";
          }
        }


      return $document;


        my $table = XML::Element.new(
                      :name('table'),
                      :attribs( { class => 'red', id => 'stat-id'})
                    );

        for ^4 {
          my $tr = XML::Element.new(:name('tr'));
          $table.append($tr);
          my $td = XML::Element.new(:name('td'));
          $tr.append($td);
          $td.append(XML::Text.new(:text('data 1')));

          $td = XML::Element.new(:name('td'));
          $tr.append($td);
          $td.append(XML::Text.new(:text('data 2')));

          $td = XML::Element.new(:name('td'));
          $tr.append($td);
          $td.append(XML::Text.new(:text('data 3')));
        }

        return $table;
      }
    };

    method include ( XML::Element $parent, Hash $attrs ) {
      my $type = $attrs<type> // 'reference';
      my $reference = $attrs<reference> // '';
      my $document;
      given $type {
        when 'reference' {

        }

        when 'include' {

          # Check if readable
          #
          if $reference.IO ~~ :r {

            # Read the content
            #
            my $sxml-text = slurp($reference);

            # Create the parser object and parse its content. Important to
            # encapsulate the content in another tag because parsing will
            # fail if thare are more than one top level elements.
            #
            my Semi-xml $x .= new;
            $x.parse(:content("\$XX-XX-XX\[$sxml-text\]"));

            # Replace all elements below the container tag XX-XX-XX
            # in the parent element of the container.
            #
            for $parent.nodes -> $node {
              if $node.name eq 'XX-XX-XX' {
                for $node.nodes -> $x-node {
                  $parent.append($x-node);
                }

                $node.remove;
                last;
              }
            }

#                $document = $x.actions.xml-document.root;
#                say "D: ", $document, "\n" ~ $x;

#    my $grammar = Semi-xml::Grammar.new;
#    my $actions = Semi-xml::Actions.new();
#say "P1a: ", $actions;
#    my $sts = $grammar.parse( "\$X\[$sxml-text\]", :actions($actions));
#say "P2a: ", $sts ?? 'OK' !! 'NOK';
          }

          else {
            say "Reference '$reference' not found";
          }
        }

        default {
          say "Type $type not recognized with \$!include";
        }
      }


    return $document;


      my $table = XML::Element.new(
                    :name('table'),
                    :attribs( { class => 'red', id => 'stat-id'})
                  );

      for ^4 {
        my $tr = XML::Element.new(:name('tr'));
        $table.append($tr);
        my $td = XML::Element.new(:name('td'));
        $tr.append($td);
        $td.append(XML::Text.new(:text('data 1')));

        $td = XML::Element.new(:name('td'));
        $tr.append($td);
        $td.append(XML::Text.new(:text('data 2')));

        $td = XML::Element.new(:name('td'));
        $tr.append($td);
        $td.append(XML::Text.new(:text('data 3')));
      }

      return $table;
    }

  }
}
