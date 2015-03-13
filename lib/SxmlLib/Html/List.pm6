use v6;

BEGIN {
  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
}

use Semi-xml;
use XML;

# Package cannot be placed in Semi-xml/Lib and named File.pm6. Evaluation seems
# to fail not finding the symbol &File when doing so.
#
package SxmlLib {

  class Html::List {
    has Hash $.symbols = {};
    
    method dir-list ( XML::Element $parent, Hash $attrs ) {
      my Str $directory = $attrs<directory> // '.';
      my Bool $recursive = $attrs<recursive>.defined;
      






      my @files = ($directory);
      my @files-to-process = @files;                # Copy to rw-able array.
      while @files-to-process.shift() -> $file {    # for will not go past the
                                                # initial number of elements
say "F: $file, {$file.IO.absolute()}";

        # Process directories
        #
        if $file.IO ~~ :d {
          my $dir := $file;                   # Alias to proper name

          if $recursive {
            my @new-files = dir( $dir, :Str);
            @files-to-process.push(sort @new-files);
          }

#          else {
#            say "Skip directory $directory";
#          }

        }

        # Process plain files
        #
        elsif $file.IO ~~ :f {
        }

        # Ignore other type of files
        #
        else {
          say "File $file is ignored, it is a special type of file";
        }
      }




    }
  }
}
