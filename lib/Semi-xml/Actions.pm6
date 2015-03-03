use v6;

class Semi-xml::Actions {
  my Str $tag;
  my Str $attr-txt;
#  my Hash $attrs;
  my Str $attr-key;

  method tag-name ( $match ) {

say "||$match||";
#!!!!!!!!!!! Variables must stored per level of nesting!!!!!!!!!!!!!!!!
    $tag = Str;
    $attr-txt = Str;
    $attr-key = Str;

#    $attrs = {};
    if ::{~$match} {
      $tag = ::{~$match};
    }

#`{{    
    elsif CALLER::{~$match} {
      $tag = CALLER::{~$match};
    }
    
    elsif OUTER::{~$match} {
      $tag = OUTER::{~$match};
    }
    
    elsif DYNAMIC::{~$match} {
      $tag = DYNAMIC::{~$match};
    }
}}

    else {
      $tag = ~$match;
      $tag ~~ s/\$//;
    }

#say " -> $tag";
  }

  method attr-key ( $match ) {
say "attr key $match";
    $attr-key = ~$match;
  }

  method attr-value ( $match ) {
say "attr value $match";
#    $attrs = {$attr => ~$match};

    $attr-txt ~= "$attr-key='$match' ";
  }

  method body-contents ( $match ) {
    my Str $tag-txt = '';
    my $tagname = $tag;
    $tagname ~~ s/\s.*$$//;

    $tag-txt = $tagname;

    if ?$attr-txt {
      $attr-txt ~~ s/\s+$$//;
      $tag-txt ~= " $attr-txt";
    }

say "\n-----\nBody:\n$match\n-----";
    if ~$match ~~ m/^^\s*$$/ {
say "<$tag-txt />";
    }

    else {
say "<$tag-txt>$match\</$tagname>";
    }
  }
}
