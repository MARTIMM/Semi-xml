use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<github:MARTIMM>;

use XML;
use XML::XPath;
use SemiXML::Sxml;
use SxmlLib::SxmlHelper;
use SxmlLib::Testing::Testing;

#-------------------------------------------------------------------------------
class Test {

  has $!sxml;

  has XML::Element $!html;
  has XML::Element $!body;

  # the program code to be run with prove
  has Str $!program-text;
  has Str $!test-filename;

  has Str $!language = 'perl6';

  has Bool $!highlight-code = False;
  has Str $!highlight-language = '';
  has Str $!highlight-skin = '';
  has Bool $!linenumbers = False;
  has Int $!line-number;

  has Bool $!initialized = False;

  enum Test-lines-entry <LINENUMBER TESTTYPE TESTRESULT CHAPTER DIAGNOSTIC>;
  has Array $!test-lines = [];

  has Str $!chapter-test-title = 'No test title';

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $!sxml, Hash $attrs ) {

    return if $!initialized;

    # things to highlight code using google prettify
    $!highlight-code = ($attrs<lang> // '').Str.Bool;
    $!language = $!highlight-language = ($attrs<lang> // 'perl6').Str;
    $!highlight-skin = lc(($attrs<highlight-skin> // 'prettify').Str);
    $!highlight-skin = 'prettify' if $!highlight-skin eq 'default';
    $!linenumbers = ($attrs<linenumbers> // '').Str.Bool;

    # start of perl6 test code data. starting linenumeber is set to 4
    $!program-text = Q:to/EOINIT/;
      use v6;
      use Test;
      #use MONKEY-SEE-NO-EVAL;

      EOINIT
    $!line-number = 5;

    $!test-filename = $SemiXML::Sxml::filename;
    $!test-filename ~~ s/ '.sxml' $/.t/;

    self!initialize-report($attrs);
    $!initialized = True;
  }

  #-----------------------------------------------------------------------------
  method run (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    $!body.append($content-body);
    $parent.append($!html);

    self!run-tests;

    $parent
  }

  #-----------------------------------------------------------------------------
  method code (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
    self!wrap-code( $parent, $content-body, $attrs, :type<code>);
    $parent
  }

  #-----------------------------------------------------------------------------
  method skip (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
    self!wrap-code( $parent, $content-body, $attrs, :type<skip>);
    $parent
  }

  #-----------------------------------------------------------------------------
  method todo (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {
    self!wrap-code( $parent, $content-body, $attrs, :type<todo>);
    $parent
  }

  #-----------------------------------------------------------------------------
  method chapter (
    XML::Element $parent, Hash $attrs,
    XML::Element :$content-body, Array :$tag-list

    --> XML::Node
  ) {

    $!chapter-test-title = ($attrs<title>//'No test title').Str;

    drop-parent-container($content-body);

    # search for the aside check panels
    my XML::Document $document .= new($content-body);
    my $x = XML::XPath.new(:$document);
    for $x.find( '//pre', :to-list) -> $acheck {
note "Pre A: ", ~$acheck.attribs<class>;
      # skip if <pre> is not an aside check
      next unless $acheck.attribs<class> ~~ m/ 'aside-check' /;

      $acheck.set( 'title', $!chapter-test-title);
    }

    append-element( $parent, 'h2', :text($!chapter-test-title));
    $parent.append($content-body);

    $parent
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

    if $!highlight-code {

      # temporary check of RESOURCES path when using uninstalled version
      my $css = %?RESOURCES{"google-code-prettify/$!highlight-skin.css"}.Str;
      append-element(
        $head, 'link', {
          :href("file://$css"),
          :type<text/css>, :rel<stylesheet>
        }
      );

      my Str $js = %?RESOURCES<google-code-prettify/prettify.js>.Str;
      my XML::Element $jse = append-element(
        $head, 'script', { :src("file://$js"), :type<text/javascript>}
      );
      append-element( $jse, :text(' '));
    }

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
    $!body.set( 'onload', 'prettyPrint()') if $!highlight-code;

    # if there is a title attribute, make a h1 title
    append-element(
      $!body, 'h1', { id => '___top', class => 'title'},
      :text(~$attrs<title>)
    ) if ? $attrs<title>;
  }



#`{{
    # Experiment to wrap all in EVALs
    $code-text ~~ s:g/ ( \n \s* ['is'||'isnt'||'is-deeply'||'is-approx'||'like'||'unlike'||'cmp-ok'||'ok'||'nok'] '('? \s+ )
                       ( <-[,]>* ) ( <-[;]>* )
                     /$/[0]EVAL\('try {$/[1]}'\)$/[2]; note \$! if ? \$!/;
note $code-text;
}}

  #-----------------------------------------------------------------------------
  method !wrap-code (
    XML::Element $parent, XML::Element $code, Hash $attrs, :$type
  ) {

    # get code text from code element
    my Str $code-text = self!get-code-text($code);

    # wrap in a subtest if a title attribute is found
    $code-text = self!wrap-subtest( $code-text, $attrs);

    # add some code depending on code type
    $code-text = self!wrap-type( $type, $code-text, $attrs);

    # gather the line numbers where the tests are written
    self!save-testlines($code-text);

    # insert place to display the code
    self!create-code-element( $parent, $code-text);

    # insert place to display the test results
    self!create-test-result( $parent, $code-text);

    # add to total code text to be run later
    $!program-text ~= $code-text;
  }

  #-----------------------------------------------------------------------------
  method !get-code-text ( XML::Element $code --> Str ) {

    drop-parent-container($code);

    # remove starting new-line if there is one
    my Str $code-text = '';
    for $code.nodes -> $node {
      my Str $snode = ~$node;
      $snode ~~ s/^ \n//;
      $code-text ~= $snode;
    }

    $code-text
  }

  #-----------------------------------------------------------------------------
  method !wrap-subtest ( Str $code-text is copy, Hash $attrs --> Str ) {

    # if title is given wrap code in a subtest
    if ? $attrs<title> {
      my Str $ct = "subtest '$attrs<title>', \{\n";
      for $code-text.lines -> $l {
        $ct ~= "  $l\n";
      }
      $code-text = "$ct}\n";
    }

    $code-text
  }

  #-----------------------------------------------------------------------------
  method !wrap-type ( Str $type, Str $code-text is copy, Hash $attrs --> Str ) {

    given $type {
      when 'skip' {
        my Int $n = ($attrs<n>//1).Str.Int;
        my Str $reason = ($attrs<reason>//'some reason').Str;
        my Str $test = ($attrs<test>//'1').Str;

        my Str $ct = "if $test \{\n";
        for $code-text.lines -> $l {
          $ct ~= "  $l\n";
        }
        $code-text = "$ct}\nelse \{\n  skip '$reason', $n;\n}\n";
      }

      when 'todo' {
        my Int $n = ($attrs<n>//1).Str.Int;
        my Str $reason = ($attrs<reason>//'some reason').Str;
        my Str $test = ($attrs<test>//'1').Str;

        $code-text = "todo '$reason', $n unless $test;\n$code-text";
      }

      # when 'code' { continue; }
      # default { }
    }

    $code-text
  }

  #-----------------------------------------------------------------------------
  # find the test code lines and store the line numbers in $!test-lines
  method !save-testlines ( Str $code-text ) {

    my $lc = $!line-number;
    for $code-text.lines -> $l {

      # check if it is one of the test lines
      if $l ~~ m:s/ ^ \s*
                    [ pass | flunk | ok |
                      nok | cmp\-ok | is | isnt | is\-deeply |
                      is\-approx | like | unlike | use\-ok | isa\-ok |
                      does\-ok | can\-ok | dies\-ok | lives\-ok |
                      eval\-dies\-ok | eval\-lives\-ok | throws\-like |
                      subtest
                    ]

                  / {

        # then see if it is one of subtest or throws-like. these test results
        # have indented output
        if $l ~~ m:s/^ \s* subtest / {
          $!test-lines.push([ $lc, 's']);
        }

        elsif $l ~~ m:s/^ \s* throws\-like / {
          $!test-lines.push([ $lc, 't']);
        }

        # the rest is normal
        else {
          $!test-lines.push([ $lc, 'n']);
        }
      }

      $lc++;
    }
  }

  #-----------------------------------------------------------------------------
  # create a <pre> element where code is displayed
  method !create-code-element( XML::Element $parent, $code-text) {

    # setup class
    my Str $class = 'test-block-code';
    if $!highlight-code {
      $class = "prettyprint $!highlight-language";
      $class ~= " linenums:$!line-number" if $!linenumbers;
    }

    # add the code text to the report document
    append-element( $parent, 'pre', {:$class}, :text($code-text));
  }

  #-----------------------------------------------------------------------------
  method !create-test-result( XML::Element $parent, $code-text ) {

    my Int $nlines = $code-text.lines.elems;
    my $aside-check = " \n" x $nlines;
    append-element(
      $parent, 'pre', {
        :class("aside-check"),
        :name("aside{$!line-number}nl{$nlines}"),
        :title('No test title')
      },
      :text($aside-check)
    );
#note "LN: $!line-number, $nlines";

    # update the line number count for the next code block
    $!line-number += $nlines;

    # insert a cleaner div below to prevent any disturbences of the two <pre>
    append-element( $parent, 'div', {:class('cleaner')});
  }

  #-----------------------------------------------------------------------------
  method !run-tests ( ) {

    note "\n---[ Prove output ]", '-' x 61;
    note " ";

    # run the tests
    my Array $result-lines = self!get-test-result;
    my @lines = |$result-lines[0];
    my @diag-lines = |$result-lines[1];

    # interprete test results
    my Int $indent = 0;
    my Int $prev-indent = 0;
    my Int $test-lines-idx = 0;
    #my Int $subtest-index;
    #my Int $throws-like-index;
    my Bool $throws-like-test = False;
    my Array $idx-stack = [];

    for @lines -> $line {
      $line ~~ /^ (\s*) (['not' \s+]? 'ok') /;

      if $/.defined {
#        note $line;

        # stick to the last one if w've gone too far
        $test-lines-idx -= 1 unless $!test-lines[$test-lines-idx].defined;

#note "Line : $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')], $line";

        # if indent increases, it could have been a subtest or a throws-like
        $indent = (~$/[0]).chars;
        if $indent > $prev-indent {
#note "Indented... $test-lines-idx, $!test-lines[$test-lines-idx][1] (push)";
          if $!test-lines[$test-lines-idx][TESTTYPE] eq 's' {
            $idx-stack.push($test-lines-idx);

            # a subtest does show when decreasing indent. this line is the first
            # test in the subtest
#note ">>> s: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')]";
            $test-lines-idx++;
            $!test-lines[$test-lines-idx].push(~$/[1]);
#note ">>> x: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')], $line";
          }

          elsif $!test-lines[$test-lines-idx][TESTTYPE] eq 't' {
#note ">>> t: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')]";

            $idx-stack.push($test-lines-idx);
            $throws-like-test = True;
#            $test-lines-idx++;
          }

          $test-lines-idx++;
          $prev-indent = $indent;
        }

        # if indent decreases, it could have been the
        # end of a subtest or a throws-like
        elsif $indent < $prev-indent {
#note "Compare $indent < $prev-indent (pop)";

          my $stack-idx = $idx-stack.pop;
          if $!test-lines[$stack-idx][TESTTYPE] eq 's' {
            $!test-lines[$stack-idx].push(~$/[1]);
#note "<<< s: $test-lines-idx, \[$!test-lines[$stack-idx][*].join(',')]";
          }

          elsif $!test-lines[$stack-idx][TESTTYPE] eq 't' {
            $!test-lines[$stack-idx].push(~$/[1]);
            $throws-like-test = False;
#note "<<< t: $test-lines-idx, \[$!test-lines[$stack-idx][*].join(',')]";
          }

          #$test-lines-idx++;
          $prev-indent = $indent;
        }

        else {
          next if $throws-like-test;
          $!test-lines[$test-lines-idx].push(~$/[1]);
#note "    n: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')], $line";
          $test-lines-idx++;
        }
      }
    }

    note "\n---[ End prove output ]", '-' x 57;
    note " ";
    .note for @diag-lines;
    note "\n---[ End prove diagnostics ]", '-' x 52;
    note " ";

note "Test Lines: ", (map {"[$_]"}, @$!test-lines).join(',');

    self!modify-aside-check-panels;
  }

  #-----------------------------------------------------------------------------
  # run the tests using perl5 prove and get the result lines
  method !get-test-result ( --> Array ) {

    # finish program and write to test file
    $!program-text ~= "\n\ndone-testing;\n";

    note "\nWrite test code to $!test-filename";
    $!test-filename.IO.spurt($!program-text);

    #'--timer', '--merge', "--archive $!test-filename.tgz",
    my Proc $p = run 'prove', '--exec', 'perl6', '--verbose',
                     '--ignore-exit', '--failures', "--rules='seq=**'",
                     '--nocolor', '--norc',
                     $!test-filename, :out, :err;

    # read lines from pipe from testing command
    my @lines = $p.out.lines;
    my @diag-lines = $p.err.lines;

    try {
      $p.out.close;
      $p.err.close;
      CATCH { default {}}
    }

    [ @lines, @diag-lines]
  }

  #-----------------------------------------------------------------------------
  method !modify-aside-check-panels ( ) {

    my Int $test-lines-idx = 0;

    # search for the aside check panels
    my XML::Document $document .= new($!html);
    my $x = XML::XPath.new(:$document);
    for $x.find( '//pre', :to-list) -> $acheck {

      # skip if <pre> is not an aside check
      next unless $acheck.attribs<class> ~~ m/ 'aside-check' /;

      # get start line number and the number of line in the aside
      my $start-line = $acheck<name>;
      $start-line ~~ s/^ 'aside' //;
      my $nlines = $start-line;
      $start-line ~~ s/ 'nl' \d+ $//;
      $start-line .= Int;
      $nlines ~~ s/^ \d+ 'nl' //;
      $nlines .= Int;

      my $chapter = $acheck<title>;
note "Chapter $chapter";

      # initialize and empty the aside <pre> element
#      my @lines = [ ' ' xx $nlines ];
      for $acheck.nodes -> $n {
        $n.remove;
      }

      # loop over the test lines and set the results from the tests
      loop ( my $i = 0; $i < $nlines; $i++) {

        # check if there are still test lines left
        if $!test-lines[$test-lines-idx].defined {

note "Loop: $start-line + $i, $test-lines-idx, $!test-lines[$test-lines-idx][0]";
          # check if line count matches the test-lines number
          if ($start-line + $i) == $!test-lines[$test-lines-idx][LINENUMBER] {

            my Str $class;
            if $!test-lines[$test-lines-idx][TESTRESULT] ~~ /:s not ok/ {
              $class = 'red';
            }

            else {
              $class = 'green';
            }

            append-element(
              $acheck, 'strong', {:$class},
              :text($!test-lines[$test-lines-idx][TESTRESULT] ~ "\n")
            );

            # add chapter to the test lines
            $!test-lines[$test-lines-idx][CHAPTER] = $chapter;

            # on to the next test
            $test-lines-idx++;
          }

          else {
            append-element( $acheck, 'strong', :text("\n"));
          }
        }

        # fill last lines up
        else {
          append-element( $acheck, 'strong', :text("\n"));
        }
      }

#note "\nLines aside: $start-line, $nlines, ", (map { "'$_'" }, @lines).join(', ');
#      append-element( $acheck, :text(@lines.join("\n") ~ " \n"));
    }
  }
}
