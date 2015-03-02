use v6;
use Semi-xml::Grammar;
use Semi-xml::Actions;

class Semi-xml:ver<0.1.0> {

  method parse ( :$content ) {

    my Semi-xml::Actions $actions .= new();
    Semi-xml::Grammar.parse( $content, :actions($actions));
#    Semi-xml::Grammar.subparse( $content, :actions($actions));
  }
}
