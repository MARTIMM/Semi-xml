use v6;

class Semi-xml::Actions {
  my Str $tag;
#  has Int $.table-count = 0;

  method tag ( $match ) {

#    my $html = 'html-2';
#    say "X: ", ::{~$match}, ', ';
    print ~$match;

    $tag = Str;
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

    say " -> $tag";
  }

  method attr-key ( $match ) {
    say "attr key $match";
  }

  method attr-value ( $match ) {
    say "attr value $match";
  }
}
