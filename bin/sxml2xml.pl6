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

  has Hash $!configuration = {
             options => {
               doctype => { show => 1},
               xml-prelude => { show => 0 },
             }
           };
}

my Semi-xml $x .= new;
$x does MARTIM-GITHUB-IO;

#-------------------------------------------------------------------------------
#
sub MAIN( $filename ) {

  if $filename.IO ~~ :r {
    my $result-filename = $filename;
    $result-filename ~~ s/\.<-[\.]>+$$/.html/;

    $x.parse-file(:$filename);
    $x.save(:filename($result-filename));
  }

  else {
    say "File $filename not readable";
    exit(1);
  }
}

