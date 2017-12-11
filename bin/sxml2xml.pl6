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
sub MAIN (
  Str $filename, Str :$in = 'xml', Str :$out = 'xml',
  Bool :$merge = False, Bool :$force = False
) {

  my SemiXML::Sxml $x .= new( :$merge, :refine([ $in, $out]), :$force);
  $x.save if $x.parse(:$filename);
}
