use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Globals;
use SemiXML::Sxml;
use SemiXML::Element;
use SxmlLib::File;
use Config::TOML;

#-------------------------------------------------------------------------------
class Summary {

  has SemiXML::Element $!html;
  has SemiXML::Element $!body;

  has Bool $!initialized = False;
  has SemiXML::Globals $!globals .= instance;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Element $m ) {

    return if $!initialized;

    self!initialize-report($m.attributes);
    $!initialized = True;
  }

  #-----------------------------------------------------------------------------
  method report ( SemiXML::Element $m ) {

    # throw the whole shebang into the body
    my SemiXML::Element $hook = $!body.append('test:hook');
    $hook.after($_) for $m.nodes.reverse;
    $hook.remove;

    # add the html to the parent
    $m.before($!html);

    self!footer;
  }

  #-----------------------------------------------------------------------------
  method preface ( SemiXML::Element $m ) {

    my SemiXML::Element $div .= new(
      :name<div>, :attributes({:class<repsection>})
    );
    $!body.append($div);

    $div.insert($_) for $m.nodes.reverse;
    $div.insert( 'h2', :attributes({:class<repheader>}), :text<Preface>);
  }

  #-----------------------------------------------------------------------------
  method load ( SemiXML::Element $m ) {

    my Str $basename = ($m.attributes<metric>//'no-metric-attribute').Str;
    my Str $path = $!globals.refined-tables<S><rootpath>;

    my SemiXML::Element $div = $!body.append(
      'div', :attributes({:class<repsection>})
    );

    my Bool $first-metric-file = True;
    my @mfs = (dir($path).grep(/ $basename '-metric-'/)>>.Str);
    if ?@mfs {
      for @mfs -> $metric-file {
        note "Load metric file '$metric-file'"
          if $!globals.trace and $!globals.refined-tables<T><file-handling>;
        self!process-metric( $div, $metric-file, :$first-metric-file);
        $first-metric-file = False;
      }
    }

    else {
      note "Metric files for '$basename' not found"
        if $!globals.trace and $!globals.refined-tables<T><file-handling>;

      $div.append(
        'h2',
        :attributes({:class<repheader>}),
        :text($basename.tc ~ ' metrics')
      );

      $div.append(
        'p',
        :attributes({:class<red>}),
        :text("TODO: Tests for '$basename' must be designed and run")
      );
    }
  }

  #-----------------------------------------------------------------------------
  method conclusion ( SemiXML::Element $m ) {

    my SemiXML::Element $div .= new(
      :name<div>, :attributes({:class<repsection>})
    );
    $!body.append($div);

    $div.insert($_) for $m.nodes.reverse;
    $div.insert( 'h2', :attributes({:class<repheader>}), :text<Conclusion>);
  }

  #===[ private methods ]=======================================================
  method !initialize-report ( Hash $attrs ) {

    $!html .= new(:name<html>, :attributes({'xml:lang' => 'en'}));
    self!head( $attrs);
    self!body( $attrs);
  }

  #-----------------------------------------------------------------------------
  method !head ( Hash $attrs ) {

    my SemiXML::Element $head = $!html.append('head');
    $head.append( 'title', :text(~$attrs<title>)) if ? $attrs<title>;
    $head.append( 'meta', :attributes({charset => 'UTF-8'}));
    $head.append(
      'meta', :attributes({ name => "description", content => "Test report"})
    );
    $head.append(
      'meta', :attributes({ :name<keywords>, content => 'sxml report summary'})
    );
    $head.append(
      'meta', :attributes({ 'http-equiv' => "language", :content<EN>})
    );

    my SemiXML::Element $hook = $head.append(
      'test:hook',
      :attributes( {
          'xmlns:test' => 'https://github.com/MARTIMM/Semi-xml/lib/SxmlLib/Test',
          :type<include-all>,
          :reference(%?RESOURCES<test-report-style.sxml>.Str)
        }
      )
    );
    my SxmlLib::File $sf .= new;
    $sf.include($hook);
    $hook.remove;
  }

  #-----------------------------------------------------------------------------
  method !body ( Hash $attrs ) {
    $!body = $!html.append('body');

    if ? $attrs<title> {
      my SemiXML::Element $t = $!body.append(
        'div', :attributes({class => 'title'})
      );

      $t.append(
        'h1',
        :attributes({class => 'title-text'}),
        :text(~$attrs<title>)
      );
    }
  }

  #-----------------------------------------------------------------------------
  method !process-metric (
    SemiXML::Element $parent, Str $metric-file,
    Bool :$first-metric-file = False
  ) {

    # read the toml config
    my %metrics = from-toml(:file($metric-file));

    # is it the first call?
    if $first-metric-file {
      # set purpose title and its purpose of the tests
      $parent.append(
        'h2', :attributes({:class<repheader>}),
        :text(%metrics<purpose><purposetitle>)
      );

      # convert some sxml into a node tree
      my SemiXML::Sxml $x .= new;
      $x.parse(
        :content(%metrics<purpose><purpose>),
        :!trace, :frag, config => { T => { :parse } }
      );

      # get the node tree and insert tree after this one
      my SemiXML::Node $tree = $x.sxml-tree;
      $x.done;

      $parent.append($tree);
    }

    my SemiXML::Element $div = $parent.append(
      'div', :attributes({:class<repbody>})
    );

    my Str $date = %metrics<general><date>;
    $date ~~ s/ 'T' / /;
    $date ~~ s/\. \d+ 'Z'//;
    $div.append(
      'strong', :attributes({:class<os>}), :text("Tested on $date (zulu),")
    );

    my Str $osdistro = %metrics<general><osdistro>.split(':')[0,2].join(' ');
    my Str $oskernel = %metrics<general><oskernel>.split(':').join(', ');
    $div.append(
      'strong', :attributes({:class<os>}), :text("on $osdistro, $oskernel")
    );

    # get names of all chapters and all chapter sections
    my Array $chapters = [| %metrics<chapters><list>];

    # find out if tests went well
    my Bool $all-chapters-have-tests = True;
    my Bool $all-tests-are-successful = True;

    for @$chapters -> $chapter {
      if %metrics<chapter>{$chapter}:exists {
        my $cc = %metrics<chapter>{$chapter};
        if ? $cc<fail> or ? $cc<todo> {
          $all-tests-are-successful = False;
        }
      }

      else {
        $all-chapters-have-tests = False;
        last;
      }
    }

    if $all-chapters-have-tests and $all-tests-are-successful {
      #my XML::Element $div = append-element( $parent, 'div', {:class<repbody>});
      $div.append('br');
      $div.append(
        'strong', :attributes({:class<green>}),
        :text(' All tests are 100% successful')
      );
    }

    else {
      my Num $percent-success = 0e0;
      my Num $percent-fail = 0e0;
      my Num $percent-todo = 0e0;
      my Num $percent-skipped = 0e0;
      my Num $total-tests = 0e0;

      # table items
      my SemiXML::Element $table = $div.append(
        'table', :attributes({:class<summary-table>})
      );

      my SemiXML::Element $tr = $table.append('tr');
      $tr.append( 'th', :attributes({:class<summary-header>}), :text<Chapter>);
      $tr.append( 'th', :attributes({:class<summary-header>}), :text<Success>);
      $tr.append( 'th', :attributes({:class<summary-header>}), :text<Fail>);
      $tr.append( 'th', :attributes({:class<summary-header>}), :text<Todo>);
      $tr.append( 'th', :attributes({:class<summary-header>}), :text<Skipped>);

      for @$chapters -> $chapter {
        $tr = $table.append('tr');
        $tr.append(
          'th', :attributes({:class('class-header align-left')}),
          :text($chapter));

        if %metrics<chapter>{$chapter}:exists {
          my $cc = %metrics<chapter>{$chapter};
  #note "sfts: $cc<success>, $cc<fail>, $cc<todo>, $cc<skipped>";
          $tr.append(
            'td', :attributes({:class<data>}), :text($cc<success>.Str)
          );
          $tr.append( 'td', :attributes({:class<data>}), :text($cc<fail>.Str));
          $tr.append( 'td', :attributes({:class<data>}), :text($cc<todo>.Str));
          $tr.append(
            'td', :attributes({:class<data>}), :text($cc<skipped>.Str)
          );

          $percent-success += $cc<success>;
          $percent-fail += $cc<fail>;
          $percent-todo += $cc<todo>;
          $percent-skipped += $cc<skipped>;
        }

        else {
          $tr.append(
            'td', :attributes({ :colspan<4>, :class<red>}),
            :text('TODO: Tests must be designed')
          );
        }
      }

      $total-tests = [+] $percent-success, $percent-fail,
                         $percent-todo, $percent-skipped;
      $percent-success *= 100.0 / $total-tests;
      $percent-fail *= 100.0 / $total-tests;
      $percent-todo *= 100.0 / $total-tests;
      $percent-skipped *= 100.0 / $total-tests;
#note "$percent-success, $percent-fail, $percent-todo, $percent-skipped";

      $tr = $table.append('tr');
      $tr.append(
        'td', :attributes({:class<summary-header>}),
        :text('Total number of tests: ' ~ $total-tests.Str)
      );
      $tr.append(
        'td', :attributes({:class<summary-header>}),
        :text($percent-success.fmt('%.2f') ~ ' %')
      );
      $tr.append(
        'td', :attributes({:class<summary-header>}),
        :text($percent-fail.fmt('%.2f') ~ ' %')
      );
      $tr.append(
        'td', :attributes({:class<summary-header>}),
        :text($percent-todo.fmt('%.2f') ~ ' %')
      );
      $tr.append(
        'td', :attributes({:class<summary-header>}),
        :text($percent-skipped.fmt('%.2f') ~ ' %')
      );
    }
  }

  #-----------------------------------------------------------------------------
  # Add footer to the end of the report
  method !footer ( ) {

    $!body.append(
      'div',
      :attributes({class => 'footer'}),
      :text( "Generated using SemiXML, SxmlLib::Testing::*," ~
             " &copy;Google prettify"
      )
    );
  }
}
