use v6;

#-------------------------------------------------------------------------------
# Package cannot be placed in SemiXML/Lib and named File.pm6. Evaluation seems
# to fail not finding the methods when doing so (perl6 2015-04).
#
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use XML;
#use SemiXML::Sxml;
use SxmlLib::SxmlHelper;

#-------------------------------------------------------------------------------
class Html::List {
  has Hash $.symbols = {};

  has Str $!directory;
  has Int @!header;
  has Str $!ref-attr;

  constant C-MAX-LEVEL = 6;
  has Int $!level = 0;
  has Bool $!first_level = True;
  has Hash $!top-level-attrs;

  #-----------------------------------------------------------------------------
  method dir-list ( XML::Element $parent,
                    Hash $attrs is copy,
                    XML::Node :$content-body   # Ignored
                  ) {

    $!directory = ~($attrs<directory>:delete) // '.';
    $!ref-attr = ~($attrs<ref-attr>:delete) // 'href';

    # Set the numbers into the array and fill it up using the last number
    # to the maximum length of C-MAX-LEVEL. So if arrey = [2,3] then
    # result will be [2,3,3,3,3,3,3]
    #
    my @list = map {.Int}, (~($attrs<header>:delete)).split(',');
    @!header.push: |@list;
    @!header.push: |(@list[@list.end] xx (C-MAX-LEVEL - +@list));

    $!top-level-attrs = $attrs;
    self!create-list( $parent, @($!directory));
  }

  #-----------------------------------------------------------------------------
  method !create-list (
    XML::Element $parent, @files-to-process is copy
    --> XML::Element
  ) {

    while @files-to-process.shift() -> $file {

      # process directories
      if $file.IO ~~ :d {

        my $dir := $file;                   # Alias to proper name

        # skip hidden directories
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

      # process plain files
      elsif $file.IO ~~ :f {
        self!make-entry( $parent, $file);
      }

      # ignore other type of files
      else {
        say "File $file is ignored, it is a special type of file";
      }
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  method !make-dir-entry ( XML::Element $parent, Str $dir-label is copy
                           --> XML::Element
                         ) {

    # place left attributes only on the first directory shown
    my XML::Element $ul = append-element( $parent, 'ul', $!top-level-attrs);
    $!top-level-attrs = %();

    my XML::Element $li = append-element( $ul, 'li');
    my XML::Element $hdr = append-element( $li, 'h' ~ @!header[$!level]);

#    $dir-label ~~ s:g/<-[\/]>+\///;
    $dir-label = $dir-label.IO.basename;
    $hdr.append(XML::Text.new(:text($dir-label)));

    return $ul;
  }

  #-----------------------------------------------------------------------------
  method !make-entry ( XML::Element $parent, Str $reference ) {
    my XML::Element $li = append-element( $parent, 'li');

    my Hash $attrs = {};
    if $!ref-attr ne 'href' {
      $attrs<href> = '';
      $attrs{$!ref-attr} = $reference;
    }

    else {
      $attrs<href> = $reference;
    }

    my XML::Element $a = append-element( $li, 'a', $attrs);

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
