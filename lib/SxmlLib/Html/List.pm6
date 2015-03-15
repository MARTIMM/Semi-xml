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
      


      my $ul = XML::Element.new(:name('ul'));
      $parent.append($ul);
      $ul.append(XML::Element.new(:name($directory)));

      my @files = ($directory);
      my @files-to-process = @files;                # Copy to rw-able array.
      self!create-list( $ul, @($directory));
    }
    
    method !create-list ( XML::Element $parent, @files-to-process ) {

      while @files-to-process.shift() -> $file {

say "F: $file, {$file.IO.absolute()}";

        # Process directories
        #
        
        if $file.IO ~~ :d {
          my $dir := $file;                   # Alias to proper name

#          if $recursive {
          my $ul = XML::Element.new(:name('ul'));
          $parent.append($ul);
          my @new-files = dir( $dir, :Str);
          self!create-list( $ul, @(sort @new-files));
#          }

#          else {
#            say "Skip directory $directory";
#          }

        }

        # Process plain files
        #
        elsif $file.IO ~~ :f {
          self!make-entry( $parent, $file);
        }

        # Ignore other type of files
        #
        else {
          say "File $file is ignored, it is a special type of file";
        }
      }
    }


    method !make-entry ( XML::Element $parent, Str $a-label ) {
      my $li = XML::Element.new(:name('li'));
      $parent.append($li);
      
      my $a = XML::Element.new(:name('a'));
      $li.append($a);
      
      $a.append(XML::Text.new(:text($a-label)));
    }
  }
}
