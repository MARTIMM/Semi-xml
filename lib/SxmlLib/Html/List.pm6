use v6.c;

#BEGIN {
#  @*INC.unshift('/home/marcel/Languages/Perl6/Projects/SemiXML/lib');
#}

use SemiXML;
use XML;

# Package cannot be placed in SemiXML/Lib and named File.pm6. Evaluation seems
# to fail not finding the methods when doing so (perl6 2015-04).
#
package SxmlLib:auth<https://github.com/MARTIMM> {

  class Html::List {
    has Hash $.symbols = {};

    has Str $!directory;
    has Int @!header;
    has Str $!ref-attr;

    constant C-MAX-LEVEL = 6;
    has Int $!level = 0;
    has Bool $!first_level = True;
    has Hash $!top-level-attrs;

    #---------------------------------------------------------------------------
    #
    method dir-list ( XML::Element $parent,
                      Hash $attrs is copy,
                      XML::Node :$content-body   # Ignored
                    ) {

      $!directory = $attrs<directory>:delete // '.';
      $!ref-attr = $attrs<ref-attr>:delete // 'href';

      # Set the numbers into the array and fill it up using the last number
      # to the maximum length of C-MAX-LEVEL. So if arrey = [2,3] then
      # result will be [2,3,3,3,3,3,3]
      #
      my @list = map {.Int}, ($attrs<header>:delete).split(',');
      @!header.push: |@list;
      @!header.push: |(@list[@list.end] xx (C-MAX-LEVEL - +@list));

      $!top-level-attrs = $attrs;
      self!create-list( $parent, @($!directory));
    }

    #---------------------------------------------------------------------------
    #
    method !create-list ( XML::Element $parent, @files-to-process is copy ) {

      while @files-to-process.shift() -> $file {

        # Process directories
        #
        if $file.IO ~~ :d {

          my $dir := $file;                   # Alias to proper name

          # Skip hidden directories
          #
          next if $dir ~~ m/^ '.' / or $dir ~~ m/ '/.' /;

          if not $!first_level {
            $!level++;
          }

          else {
            $!first_level = False;
          }

          my $ul = self!make-dir-entry( $parent, $dir);

          my @new-files = dir( $dir, :Str);
          self!create-list( $ul, @(sort @new-files));

          $!level--;
          if $!level < 0 {
            $!level = 0;
            $!first_level = True;
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
      my $ul = XML::Element.new( :name('ul'), :attribs($!top-level-attrs));
      $!top-level-attrs = %();

      $parent.append($ul);
      my $li = XML::Element.new(:name('li'));
      $ul.append($li);
      my $hdr = XML::Element.new(:name('h' ~ @!header[$!level]));
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

      $a.append(XML::Text.new(:text($a-label)));
    }
  }
}
