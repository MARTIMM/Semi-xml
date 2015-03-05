#!/usr/bin/env perl6
#
use v6;

BEGIN {
  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
}

use Semi-xml;

#-------------------------------------------------------------------------------
#
role MARTIM-GITHUB-IO {
  has Hash $!configuration = {};
}

my Semi-xml $x .= new;
$x does MARTIM-GITHUB-IO;

#-------------------------------------------------------------------------------
#
sub MAIN( $filename ) {

  if $filename.IO ~~ :r {
    $x.parse-file(:$filename);
    $x.save;
  }

  else {
    say "File $filename not readable";
    exit(1);
  }
}

