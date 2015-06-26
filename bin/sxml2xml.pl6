#!/usr/bin/env perl6
#
use v6;

BEGIN {
  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
}

use Semi-xml;

# Allow switches after positionals. Pinched from the panda program. Now it is
# possible to make the sxml file executable with the path of this program.
#
@*ARGS = @*ARGS.grep(/^ '-'/), @*ARGS.grep(/^ <-[-]>/);

#-------------------------------------------------------------------------------
#
role sxml-role {
  has Hash $.configuration = { output => { } };
}

#-------------------------------------------------------------------------------
#= sxml2xml -run run-code filename.sxml
#
sub MAIN ( $filename, Str :$run ) {
#  $filename ~~ m/(.*?)\.<{$filename.IO.extension}>$/;
#  $x.configuration<output><filename> = ~$/[0];
#say "PF: {$x.configuration<output><filename>}";


  my $dep = process-sxml( $filename, :$run);
  if $dep.defined {
    my Array $dep-list = [$dep.split(/\s* ',' \s*/)];
    for $dep-list.list -> $dependency is copy {
      $dependency ~~ s/^\s+//;
      $dependency ~~ s/\s+$//;
      say "Processing dependency $dependency";
      $dep = process-sxml( $dependency, :$run);
      $dep-list.push($dep.split(/\s* ',' \s*/)) if $dep.defined;
    }
  }
}

#-------------------------------------------------------------------------------
#
sub process-sxml ( Str $filename, Str :$run ) {

  my Semi-xml $x .= new(:init);
  $x does sxml-role;

  # Split filename in its parts
  #
  my @path-spec = $*SPEC.splitpath($filename);
  $x.configuration<output><filepath> = @path-spec[1];
  $x.configuration<output><filename> = @path-spec[2];

  # Drop extension
  #
  $x.configuration<output><filename> ~~ s/\.<-[\.]>+$//;

  if $filename.IO ~~ :r {
    $x.parse-file(:$filename);
    $x.save(:run-code($run));

    return $x.get-option( :section('dependencies'), :option('files'));
  }

  else {
    say "File $filename not readable";
    exit(1);
  }
}
