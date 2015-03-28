use v6;

BEGIN {
  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/Semi-xml/lib');
}

use Semi-xml;
use XML;

# Package cannot be placed in Semi-xml/Lib and named File.pm6. Evaluation seems
# to fail not finding the symbol &File when doing so.
#
package SxmlLib:auth<https://github.com/MARTIMM> {

  class Html::List {
    has Hash $.symbols = {};

    has Str $!directory;
    has Int @!header;
    has Str $!ref-attr;

    my Int $level = 0;
    constant $max_level = 6;
    my Bool $first_level = True;
    my Hash $top-level-attrs;

    #---------------------------------------------------------------------------
    #
    method dir-list ( XML::Element $parent,
                      Hash $attrs is copy,
                      XML::Node :$content-body   # Ignored
                    ) {
      $content-body.remove;

      $!directory = $attrs<directory>:delete // '.';
      $!ref-attr = $attrs<ref-attr>:delete // 'href';

      # Set the numbers into the array and fill it up using the last number
      # to the maximum length of $max_level
      #
      @!header = EVAL($attrs<header>:delete) // 1;
      @!header.push( @!header[@!header.end] xx ($max_level - +@!header) );

      $top-level-attrs = $attrs;
      self!create-list( $parent, @($!directory));
    }


    #---------------------------------------------------------------------------
    #
    method !create-list ( XML::Element $parent, @files-to-process ) {

      while @files-to-process.shift() -> $file {

#say "F: $file, {$file.IO.absolute()}";

        # Process directories
        #
        if $file.IO ~~ :d {
          if !$first_level {
            $level++;
          }

          else {
            $first_level = False;
          }

#say "L 0: $level";
          my $dir := $file;                   # Alias to proper name

          my $ul = self!make-dir-entry( $parent, $dir);

          my @new-files = dir( $dir, :Str);
          self!create-list( $ul, @(sort @new-files));

          $level--;
          if $level < 0 {
            $level = 0;
            $first_level = True;
          }
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

    #---------------------------------------------------------------------------
    #
    method !make-dir-entry ( XML::Element $parent, Str $dir-label is copy
                             --> XML::Element
                           ) {
      my $ul = XML::Element.new( :name('ul'), :attribs($top-level-attrs));
      $top-level-attrs = %();

      $parent.append($ul);
      my $li = XML::Element.new(:name('li'));
      $ul.append($li);
#say "L 1: $level";
      my $hdr = XML::Element.new(:name('h' ~ @!header[$level]));
      $li.append($hdr);

      $dir-label ~~ s:g/<-[\/]>+\///;
      $hdr.append(XML::Text.new(:text($dir-label)));

      return $ul;
    }

    #---------------------------------------------------------------------------
    #
    method !make-entry ( XML::Element $parent, Str $reference ) {
      my $li = XML::Element.new(:name('li'));
      $parent.append($li);

      my Hash $attrs = {};
      if $!ref-attr ne 'href' {
        $attrs<href> = '';
        $attrs{$!ref-attr} = $reference;
      }

      else {
        $attrs<href> = $reference;
      }

      my $a = XML::Element.new( :name('a'), :attribs($attrs));
      $li.append($a);

      # Cleanup the reference in such a way that it will become a nice label
      # The filename can have prefixed numbers so the sorting will automatically
      # have the proper sequence to show. The number will be removed from the
      # label.
      #
      my $a-label = $reference;
      $a-label ~~ s:g/<-[\/]>+\///;     # Remove any path leading up to the file
      $a-label ~~ s/\.<-[\.]>*$//;      # Remove file extension
      $a-label ~~ s/\d+('-'|'_')*//;    # Remove number with optional '-' or '_'
      $a-label ~~ s:g/('-'|'_')+/ /;    # Substitute '-' or '_' with space.
#say "A-Label 4: $a-label";
      $a.append(XML::Text.new(:text($a-label)));
    }
  }
}
