use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<github:MARTIMM>;

use XML;
use XML::XPath;
use SemiXML::Sxml;
use SxmlLib::SxmlHelper;
use Config::TOML;

#-------------------------------------------------------------------------------
class Summary {

  has $!sxml;

  has XML::Element $!html;
  has XML::Element $!body;

  has Bool $!initialized = False;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $!sxml, Hash $attrs ) {

    return if $!initialized;

    self!initialize-report($attrs);
    $!initialized = True;
  }

  #-----------------------------------------------------------------------------
  method report (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
    # throw the whole shebang into the body
    $!body.append($content-body);

    # add the html to the parent
    $parent.append($!html);

    self!footer;

    $parent
  }

  #-----------------------------------------------------------------------------
  method load (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    my Str $basename = ($attrs<metric>//'no-metric-attribute').Str;
    my Str $path = $SemiXML::Sxml::filename.IO.absolute;
    $path = $path.IO.dirname;

    my XML::Element $div = append-element( $parent, 'div', {:class<repsection>});

    my Bool $first-metric-file = True;
    my @mfs = (dir($path).grep(/ $basename '-metric-'/)>>.Str);
    if ?@mfs {
      for @mfs -> $metric-file {
note "F: $metric-file";
        self!process-metric( $div, $metric-file, :$first-metric-file);
        $first-metric-file = False;
      }
    }

    else {
      append-element(
        $div, 'h2', {:class<repheader>}, :text($basename.tc ~ ' metrics')
      );

      append-element(
        $div, 'p', {:class<red>},
        :text("TODO: Tests for '$basename' must be designed and run")
      );
    }

    $parent
  }

  #-----------------------------------------------------------------------------
  method conclusion (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
    my XML::Element $div = append-element( $parent, 'div', {:class<repsection>});
    append-element( $div, 'h2', {:class<repheader>}, :text<Conclusion>);
    $div.append($content-body);

    $parent;
  }

  #===[ private methods ]=======================================================
  method !initialize-report ( Hash $attrs ) {

    $!html .= new(:name<html>);
    my XML::Element $head = self!head( $!html, $attrs);

    self!body( $!html, $attrs);
  }

  #-----------------------------------------------------------------------------
  method !head ( XML::Element $html, Hash $attrs --> XML::Element ) {

    my XML::Element $head = append-element( $html, 'head');
    append-element( $head, 'title', :text(~$attrs<title>)) if ? $attrs<title>;
    append-element( $head, 'meta', {charset => 'UTF-8'});

    my $css = %?RESOURCES<report.css>.Str;
    append-element(
      $head, 'link', {
        :href("file://$css"),
        :type<text/css>, :rel<stylesheet>
      }
    );

    $head
  }

  #-----------------------------------------------------------------------------
  method !body ( XML::Element $html, Hash $attrs ) {
    $!body = append-element( $html, 'body');

    # if there is a title attribute, make a h1 title
    append-element(
      $!body, 'h1', { id => '___top', class => 'title'},
      :text(~$attrs<title>)
    ) if ? $attrs<title>;
  }

  #-----------------------------------------------------------------------------
  method !process-metric (
    XML::Element $parent, Str $metric-file, Bool :$first-metric-file = False
  ) {

    # read the toml config
    my %metrics = from-toml(:file($metric-file));

    # is it the first call?
    if $first-metric-file {
      # set purpose title and its purpose of the tests
      append-element(
        $parent, 'h2', {:class<repheader>},
        :text(%metrics<purpose><purposetitle>)
      );
      append-element(
        $parent, 'p', :text(%metrics<purpose><purpose>)
      );
    }

    my XML::Element $div = append-element( $parent, 'div', {:class<repbody>});
    my Str $osdistro = %metrics<general><osdistro>.split(':')[0..1].join(', ');
    my Str $oskernel = %metrics<general><oskernel>.split(':').join(', ');
    append-element(
      $div, 'strong', {:class<os>}, :text($osdistro ~ ', ' ~ $oskernel)
    );

    # get names of all chapters and all chapter sections
    my Array $chapters = [| %metrics<chapters><list>];

    # find out if tests went well
    my Bool $all-chapters-have-tests = True;
    my Bool $all-tests-are-successful = True;
    my Num $percent-success = 0e0;
    my Num $percent-fail = 0e0;
    my Num $percent-todo = 0e0;
    my Num $percent-skipped = 0e0;
    my Num $total-tests = 0e0;

    for @$chapters -> $chapter {
      if %metrics<chapter>{$chapter}:exists {
        my $cc = %metrics<chapter>{$chapter};
        if ? $cc<fail> or ? $cc<todo> {
          $all-tests-are-successful = False;
        }

        $percent-success += $cc<success>;
        $percent-fail += $cc<fail>;
        $percent-todo += $cc<todo>;
        $percent-skipped += $cc<skipped>;
      }

      else {
        $all-chapters-have-tests = False;
        last;
      }
    }

    if $all-chapters-have-tests and $all-tests-are-successful {
      append-element( $div, :text(' All tests are 100% successful'));
    }

    else {

      $total-tests = [+] $percent-success, $percent-fail, $percent-todo, $percent-skipped;
      $percent-success = ($percent-success / $total-tests) * 100.0;
      $percent-fail = ($percent-fail / $total-tests) * 100.0;
      $percent-todo = ($percent-todo / $total-tests) * 100.0;
      $percent-skipped = ($percent-skipped / $total-tests) * 100.0;
note "$percent-success, $percent-fail, $percent-todo, $percent-skipped";

      # table items
      my XML::Element $table = append-element( $div, 'table', {:class<summary-table>});
      my XML::Element $tr = append-element( $table, 'tr');
      append-element( $tr, 'th', {:class<summary-header>}, :text<Chapter>);
      append-element( $tr, 'th', {:class<summary-header>}, :text<Success>);
      append-element( $tr, 'th', {:class<summary-header>}, :text<Fail>);
      append-element( $tr, 'th', {:class<summary-header>}, :text<Todo>);
      append-element( $tr, 'th', {:class<summary-header>}, :text<Skipped>);

      for @$chapters -> $chapter {
        $tr = append-element( $table, 'tr');
        append-element( $tr, 'th', {:class<class-header>}, :text($chapter));

        if %metrics<chapter>{$chapter}:exists {
          my $cc = %metrics<chapter>{$chapter};
  #note "sfts: $cc<success>, $cc<fail>, $cc<todo>, $cc<skipped>";
          append-element( $tr, 'td', {:class<data>}, :text($cc<success>.Str));
          append-element( $tr, 'td', {:class<data>}, :text($cc<fail>.Str));
          append-element( $tr, 'td', {:class<data>}, :text($cc<todo>.Str));
          append-element( $tr, 'td', {:class<data>}, :text($cc<skipped>.Str));
        }

        else {
          append-element( $tr, 'td', { :colspan<4>, :class<red>},
            :text('TODO: Tests must be designed')
          );
        }
      }

      $tr = append-element( $table, 'tr');
      append-element( $tr, 'td', {:class<summary-header>}, :text('Total number of tests is ' ~ $total-tests.Str));
      append-element( $tr, 'td', {:class<summary-header>}, :text($percent-success.Str ~ ' %'));
      append-element( $tr, 'td', {:class<summary-header>}, :text($percent-fail.Str ~ ' %'));
      append-element( $tr, 'td', {:class<summary-header>}, :text($percent-todo.Str ~ ' %'));
      append-element( $tr, 'td', {:class<summary-header>}, :text($percent-skipped.Str ~ ' %'));
    }
  }

  #-----------------------------------------------------------------------------
  # Add footer to the end of the report
  method !footer ( ) {

    my XML::Element $div = append-element( $!body, 'div', {class => 'footer'});
    append-element(
      $div,
      :text( "Generated using SemiXML, SxmlLib::Testing::*," ~
             " XML, XML::XPath, &copy;Google prettify"
      )
    );
  }
}
