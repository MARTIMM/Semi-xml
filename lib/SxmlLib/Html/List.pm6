use v6;

#-------------------------------------------------------------------------------
# Package cannot be placed in SemiXML/Lib and named File.pm6. Evaluation seems
# to fail not finding the methods when doing so (perl6 2015-04).
#
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Element;

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
  method dir-list ( SemiXML::Element $m ) {

    $!directory = ~($m.attributes<directory>:delete) // '.';
    $!ref-attr = ~($m.attributes<ref-attr>:delete) // 'href';
    my Str $id = ~($m.attributes<id>:delete) // 'dir-id';

    # Set the numbers into the array and fill it up using the last number
    # to the maximum length of C-MAX-LEVEL. So if arrey = [2,3] then
    # result will be [2,3,3,3,3,3,3]
    #
    my @list = map {.Int}, (~($m.attributes<header>:delete)).split(',');
    @!header.push: |@list;
    @!header.push: |(@list[@list.end] xx (C-MAX-LEVEL - +@list));

    # convert other attributes from StringList to string
    $!top-level-attrs = (map { $^k => $^v.Str }, $m.attributes.kv).Hash;

    my SemiXML::Element $div = $m.parent.append( 'div', :attributes({:$id}));
    self!create-list( $div, @($!directory));
  }

  #-----------------------------------------------------------------------------
  method !create-list ( SemiXML::Element $parent, @files-to-process is copy ) {

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
        my @new-files = dir($dir)>>.Str;
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
  }

  #-----------------------------------------------------------------------------
  method !make-dir-entry (
    SemiXML::Element $parent, Str $dir-label is copy
    --> SemiXML::Element
  ) {

    $dir-label = $dir-label.IO.basename;
    $parent.append(
      'h' ~ @!header[$!level],
      :text($dir-label)
    );

    # place left attributes only on the first directory shown
    my SemiXML::Element $ul = $parent.append(
      'ul', :attributes($!top-level-attrs)
    );
    $!top-level-attrs = {};

    return $ul;
  }

  #-----------------------------------------------------------------------------
  method !make-entry ( SemiXML::Element $parent, Str $reference ) {

    my SemiXML::Element $li = $parent.append('li');

    my Hash $attrs = {};
    if $!ref-attr ne 'href' {
      $attrs<href> = '';
      $attrs{$!ref-attr} = $reference;
    }

    else {
      $attrs<href> = $reference;
    }

    # Cleanup the reference in such a way that it will become a nice label
    # The filename can have prefixed numbers so the sorting will automatically
    # have the proper sequence to show. The number will be removed from the
    # label.
    my $a-label = $reference;
    $a-label ~~ s:g/<-[\/]>+\///;     # Remove any path leading up to the file
    $a-label ~~ s/\.<-[\.]>*$//;      # Remove file extension
    $a-label ~~ s/\d+('-'|'_')*//;    # Remove number with optional '-' or '_'
    $a-label ~~ s:g/('-'|'_')+/ /;    # Substitute '-' or '_' with space.

    $li.append( 'a', :attributes($attrs), :text($a-label));
  }
}
