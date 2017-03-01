#!/usr/bin/env perl6
#
use v6.c;
use SemiXML::Sxml;

# Allow switches after positionals. Pinched from an older panda version. Now
# it is possible to make the sxml file executable with the path of this
# program.
#
my @a = grep( /^ <-[-]>/, @*ARGS);
@*ARGS = (|grep( /^ '-'/, @*ARGS), |@a);

#-------------------------------------------------------------------------------
#= sxml2xml -run=<run-code> filename.sxml
sub MAIN (
  Str $filename, Str :$run, Str :$in = 'xml', Str :$out = 'xml',
  Bool :$trace = False, Bool :$merge = False
) {

  my $dep = process-sxml(
    $filename, :$run, :refine([ $in, $out]), :$trace, :$merge
  );

  if $dep.defined {
    my Array $dep-list = [$dep.split(/\s* ',' \s*/)];
    for $dep-list.list -> $dependency is copy {

      $dependency ~~ s/^\s+//;
      $dependency ~~ s/\s+$//;

      say "Processing dependency $dependency";
      my $dep = process-sxml(
        $dependency, :$run, :refine([ $in, $out]), :$trace, :$merge
      ) if ? $dependency;

      $dep-list.push: |$dep.split(/\s* ',' \s*/) if ? $dep;
    }
  }
}

#-------------------------------------------------------------------------------
sub process-sxml (
  Str:D $filename is copy, Str :$run, Array :$refine,
  Bool :$trace = False, Bool :$merge = False, 
) {

  my SemiXML::Sxml $x .= new( :$trace, :$merge);

  if $filename.IO ~~ :r {
    $x.parse(:$filename);
    $filename ~~ s/ '.' $filename.IO.extention //;
    $x.save( :run-code($run), :$filename);
    my $deps = $x.get-option( :section('dependencies'), :option('files')) // '';
    return $deps;
  }

  else {
    die "File $filename not readable";
  }
}
