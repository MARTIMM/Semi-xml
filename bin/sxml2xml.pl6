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
  Str $filename, Str :$in = 'xml', Str :$out = 'xml',
  Bool :$trace = False, Bool :$merge = False
) {

#TODO procss dependencies before parsing
#TODO check for duplicate dependencies
  my Array $dep-list = process-sxml( $filename, :$in, :$out, :$trace, :$merge);

  if ? $dep-list {
#    my Array $dep-list = [$dep.split(/\s* ',' \s*/)];
    for @$dep-list -> $dependency { #is copy {

#      $dependency ~~ s/^\s+//;
#      $dependency ~~ s/\s+$//;

      say "Processing dependency $dependency";
      my Array $new-dep-list = process-sxml(
        $dependency, :$in, :$out, :$trace, :$merge
      ) if ? $dependency;

      $dep-list.push: |@$new-dep-list if ? $new-dep-list;
    }
  }
}

#-------------------------------------------------------------------------------
sub process-sxml (
  Str:D $filename is copy, Str :$in, Str :$out,
  Bool :$trace = False, Bool :$merge = False,

  --> Array
) {

  my Array $deps;
  my SemiXML::Sxml $x .= new( :$trace, :$merge, :refine([ $in, $out]));

  if $filename.IO ~~ :r {
    $x.parse(:$filename);
#    $filename ~~ s/ '.' $filename.IO.extention //;
#    $x.save( :run-code($run), :$filename);
    $x.save;
    $deps = $x.get-config( :table<D>, :key<files>) // [];
  }

  else {
    die "File $filename not readable";
  }

  return $deps;
}
