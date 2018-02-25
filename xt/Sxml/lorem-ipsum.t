use v6;
use Test;
#use MONKEY-SEE-NO-EVAL;

      use SemiXML::Sxml;
      my SemiXML::Sxml $sxml .= new(:refine([<html html>]));
      isa-ok $sxml, SemiXML::Sxml;

      my Hash $config = {
        ML => { :lorem('SxmlLib::LoremIpsum') },
        T => { :parse, :modules}
      };

      my Str $content = '$html';
      $sxml.parse( :$content, :$config, :trace);

      like ~$sxml, /:s
            '<!DOCTYPE html>'
            '<html xmlns="http://www.w3.org/1999/xhtml"></html>'
            /, "Simple html element";
          $content = q:to/EOSXML/;
        $html [
          $body [
            $p [ $!lorem.standard1500 ]
          ]
        ]
        EOSXML

      $sxml.parse( :$content, :$config, :!trace);

      like ~$sxml, /:s ^ Lorem ipsum dolor sit amet /,
                   'a bit from the beginning of standard1500';
      like ~$sxml, /:s mollit anim id est laborum '.' $/,
                   'and bit from its end of standard1500';
    

done-testing;
