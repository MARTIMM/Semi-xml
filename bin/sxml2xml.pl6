#!/usr/bin/env perl6
#
use v6;

BEGIN {
  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
}

use Semi-xml;

#-------------------------------------------------------------------------------
#
role sxml-role {
  has Hash $.configuration = { output => { } };
}

#-------------------------------------------------------------------------------
#
sub MAIN ( $filename ) {
#  $filename ~~ m/(.*?)\.<{$filename.IO.extension}>$/;
#  $x.configuration<output><filename> = ~$/[0];
#say "PF: {$x.configuration<output><filename>}";

  my $dep = process-sxml($filename);
  if $dep.defined {
    my Array $dep-list = [$dep.split(/\s* ',' \s*/)];
    for $dep-list.list -> $dependency {
      say "Processing dependency $dependency";
      $dep = process-sxml($dependency);
      $dep-list.push($dep.split(/\s* ',' \s*/)) if $dep.defined;
    }
  }
}

#-------------------------------------------------------------------------------
#
sub process-sxml ( $filename ) {

  my Semi-xml $x .= new(:init);
  $x does sxml-role;

  my @path-spec = $*SPEC.splitpath($filename);
  $x.configuration<output><filepath> = @path-spec[1];
  $x.configuration<output><filename> = @path-spec[2];
  $x.configuration<output><filename> ~~ s/\.<-[\.]>+$//;
#say "PS: @path-spec[]";

  if $filename.IO ~~ :r {
    $x.parse-file(:$filename);
    $x.save;
    return $x.get-option( :section('dependencies'), :option('files'));
  }

  else {
    say "File $filename not readable";
    exit(1);
  }
}
