#!/usr/bin/env perl6
#
use v6;
use SemiXML::Sxml;

# Allow switches after positionals. Pinched from an older panda version. Now
# it is possible to make the sxml file executable with the path of this
# program.
#
# When switches are given in the Unix hash-bang command the text after the
# command is one string. This must be split first and pushed separately.
my @a;
for grep( /^ '--'/, @*ARGS) -> $a {
  for $a.split( /\s+ <?before '--'>/ ) {
    @a.push: $^a;
  }
}

@*ARGS = ( |@a, |grep( /^ <-[-]>/, @*ARGS));

#for @*ARGS {
#  note "A: $^a";
#}


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
