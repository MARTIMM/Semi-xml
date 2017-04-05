use v6;
use Test;
use SemiXML::Sxml;

#-------------------------------------------------------------------------------
# Testing;
#   Translation of SemiXML text in file
#   Result to file
#-------------------------------------------------------------------------------
# Setup
# Write file
#
my $dir = 't/D101';
my $filename = "$dir/test-file.sxml";
mkdir $dir unless $dir.IO ~~ :e;

spurt( $filename, q:to/EOSX/);

$html [
  $body [                                       # Body
    $h1 [ Data from file \# h1 ]                # outside h1
    $table [ data                               # table
      $tr [ trrr                                # trrr
        $th[header \# th ]                      # outside th
        $td[data \# td ]                        # outside td
        $td [! # inside protected body !]
      ]
    ][
    # comment on its own in 2nd body
    ]
  ]
]
EOSX

# Parse
my SemiXML::Sxml $x .= new( :trace, :merge, :refine([<xml xml>]));
$x.parse(:$filename);

my Str $xml-text = ~$x;
ok $xml-text ~~ m/\<html\>/, 'Top level html found';
ok $xml-text !~~ m/\<head\>/, 'Head not found';
ok $xml-text ~~ ms/Data from file/, 'Section text found';
#todo 'comments are not implemented yet', 1;
unlike $xml-text, /:s '#' 'outside' 'h1' /, 'comment removed';
unlike $xml-text, /:s '#' 'trrr' /, 'comment also removed';
like $xml-text, /:s '#' 'inside' 'protected' 'body' /, 'comment not removed';
like $xml-text, /:s 'header' '#' 'th' /, 'escaped # not removed';

#note $xml-text;


# Write xml out to file. Default extention is .xml
my $fout = $filename;
$fout ~~ s/\.sxml//;
$x.save(:$fout);
ok "$fout.xml".IO ~~ :e, "File $fout.xml written";

#-------------------------------------------------------------------------------
# Cleanup
unlink $filename;
unlink "$fout.xml";
rmdir $dir;

done-testing;
exit(0);
