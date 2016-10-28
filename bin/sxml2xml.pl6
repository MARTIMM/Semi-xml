#!/usr/bin/env perl6
#
use v6.c;
use SemiXML;

# Allow switches after positionals. Pinched from an older panda version. Now
# it is possible to make the sxml file executable with the path of this
# program.
#
my @a = grep( /^ <-[-]>/, @*ARGS);
@*ARGS = (|grep( /^ '-'/, @*ARGS), |@a);

#-------------------------------------------------------------------------------
#`{{
role sxml-role {
  has Hash $.user-configuration = { output => { } };
}
}}

#-------------------------------------------------------------------------------
#= sxml2xml -run run-code filename.sxml
sub MAIN ( Str $filename, Str :$run ) {

  my $dep = process-sxml( $filename, :$run);
  if $dep.defined {
    my Array $dep-list = [$dep.split(/\s* ',' \s*/)];
    for $dep-list.list -> $dependency is copy {
      $dependency ~~ s/^\s+//;
      $dependency ~~ s/\s+$//;
      say "Processing dependency $dependency";
      my $dep = process-sxml( $dependency, :$run) if ? $dependency;
      $dep-list.push: |$dep.split(/\s* ',' \s*/) if ? $dep;
    }
  }
}

#-------------------------------------------------------------------------------
sub process-sxml ( Str:D $filename, Str :$run ) {

  my SemiXML::Sxml $x .= new(:init);
#  $x does sxml-role;

  # Split filename in its parts
#say $*SPEC;
#  my @path-spec = $*SPEC.splitpath($filename);
#  $x.configuration<output><filepath> = @path-spec[1];
#  $x.configuration<output><filename> = @path-spec[2];

  # Drop extension
#  $x.configuration<output><filename> ~~ s/\.<-[\.]>+$//;

  if $filename.IO ~~ :r {
    my $X = $x.parse-file(:$filename);
    $x.save(:run-code($run));
    my $deps = $x.get-option( :section('dependencies'), :option('files')) // '';
    return $deps;
  }

  else {
    die "File $filename not readable";
  }
}
