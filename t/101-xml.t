use v6;
use Test;
use Semi-xml;

#-------------------------------------------------------------------------------
# Testing;
#   Translation of smi-xml text in file
#   Result to file
#-------------------------------------------------------------------------------
# Setup
# Write file
#
my $filename = 't/test-file.sxml';
spurt( $filename, q:to/EOSX/);
$html [
  $body [                                       # Body
    $h1 [ Data from file \# h1 ]                # outside h1
    $table [ data                               # table
      $tr [ trrr                                # trrr
        $th[header \# th ]                      # outside th
        $td[data \# td ]                        # outside td
      ]
    ]
  ]
]
EOSX

# Parse
#
my Semi-xml $x .= new;
$x.parse-file(:$filename);

my Str $xml-text = ~$x;
ok $xml-text ~~ m/\<html\>/, 'Top level html found';
ok $xml-text !~~ m/\<head\>/, 'Head not found';
ok $xml-text ~~ ms/Data from file/, 'Section text found';

say $xml-text;

unlink $filename;

# Write xml out to file
#
$filename ~~ s/\.sxml/.xml/;
$x.save(:$filename);
ok $filename.IO ~~ :e, "File written";

unlink $filename;

#-------------------------------------------------------------------------------
# Cleanup
#
done();
exit(0);
