use v6;

class Semi-xml::Actions {
  has Str $tag;
#  has Int $.table-count = 0;

  method tag ( $match ) {
    $tag = 'xml';
    my $x = '$tag';
    say "X: ", ::{$x};
    say MY::{~$match}, ::{~$match};
    print ~$match;

    $tag = Str;
    if MY::{~$match} {
      $tag = MY::{~$match};
    }
    
    elsif CALLER::{~$match} {
      $tag = CALLER::{~$match};
    }
    
    elsif OUTER::{~$match} {
      $tag = OUTER::{~$match};
    }
    
    elsif DYNAMIC::{~$match} {
      $tag = DYNAMIC::{~$match};
    }
    
    else {
      $tag = ~$match;
      $tag ~~ s/\$//;
    }

    say " -> $tag";
  }
}
