use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

#our $actions = Semi-xml::Actions.new();

class Semi-xml:ver<0.4.0> {

  has Semi-xml::Actions $actions = Semi-xml::Actions.new();

  method parse-file ( :$file ) {
    if $file.IO ~~ :r {
      my $text = slurp($file);
      return self.parse( :content($text) );
    }
  }

  method parse ( :$content ) {

    my Hash $styles;
    my Hash $configuration;

    # Get user introduced attribute information
    #
    for self.^attributes -> $class-attr {
      given $class-attr.name {
        when '$!styles' {
          $styles = $class-attr.get_value(self);
        }

        when '$!configuration' {
          $configuration = $class-attr.get_value(self);
        }
      }
#say $class-attr.name, ', ', $class-attr.get_value(self).^name;
    }

#say "P: ", $styles, ', ', $configuration;

#    my Semi-xml::Actions $actions .= new();
    Semi-xml::Grammar.parse( $content, :actions($actions));
#    Semi-xml::Grammar.subparse( $content, :actions($actions));
  }

  method Str () {
    return ~$actions.xml-document;
  }

}

multi sub prefix:<~>(Semi-xml $x) {
  return ~$x.actions.xml-document;
}
