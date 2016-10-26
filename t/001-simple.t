use v6.c;
use Test;


    use SemiXML;

    # Convenience routine
    sub parse ( Str $content --> Str ) {

      state SemiXML::Sxml $x .= new;
      my ParseResult $r = $x.parse(:$content);

      my Str $xml = ~$x;
      $xml;
    }

    my $xml = parse('$st []');
is $xml, '<st/>', 'T0';


done-testing;
