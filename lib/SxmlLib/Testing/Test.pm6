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

  has Bool $!highlight-code = False;
  has Str $!highlight-language = '';
  has Str $!highlight-skin = '';
  has Bool $!linenumbers = False;
  has Int $!line-number;

  has Bool $!initialized = False;

  has Array $!test-lines = [];

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $!sxml, Hash $attrs ) {

    return if $!initialized;

    # things to highlight code using google prettify
    $!highlight-code = ($attrs<highlight-lang> // '').Str.Bool;
    $!highlight-language = ($attrs<highlight-lang> // '').Str;
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

  #-----------------------------------------------------------------------------
  method !wrap-code (
    XML::Element $parent, XML::Element $code, Hash $attrs, :$type
  ) {

    my Str $code-text = self!get-code-text($code);

#`{{
    # Experiment to wrap all in EVALs
    $code-text ~~ s:g/ ( \n \s* ['is'||'isnt'||'is-deeply'||'is-approx'||'like'||'unlike'||'cmp-ok'||'ok'||'nok'] '('? \s+ )
                       ( <-[,]>* ) ( <-[;]>* )
                     /$/[0]EVAL\('try {$/[1]}'\)$/[2]; note \$! if ? \$!/;
note $code-text;
}}

    # if title is given wrap code in a subtest
    if ? $attrs<title> {
      my Str $ct = "subtest '$attrs<title>', \{\n";
      for $code-text.lines -> $l {
        $ct ~= "  $l\n";
      }
      $code-text = "$ct}\n";
    }

    # add some code depending on code type
    given $type {
      when 'skip' {
        my Int $n = ($attrs<n>//1).Str.Int;
        my Str $reason = ($attrs<reason>//'some reason').Str;
        my Str $test = ($attrs<test>//'1').Str;

        my Str $ct = "\nif $test \{\n";
        for $code-text.lines -> $l {
          $ct ~= "  $l\n";
        }
        $code-text = "$ct}\nelse \{\n  skip '$reason', $n;\n}\n";
      }

      when 'todo' {
        my Int $n = ($attrs<n>//1).Str.Int;
        my Str $reason = ($attrs<reason>//'some reason').Str;
        my Str $test = ($attrs<test>//'1').Str;

        $code-text = "\ntodo '$reason', $n unless $test;\n$code-text";
      }

      # when 'code' { continue; }
      # default { }
    }

    # gather the line numbers where the tests are written
    my $lc = $!line-number;
    for $code-text.lines -> $l {

      if $l ~~ m:s/ ^ \s*
                    [ todo | skip | skip\-rest | pass | flunk | ok |
                      nok | cmp\-ok | is | isnt | is\-deeply |
                      is\-approx | like | unlike | use\-ok | isa\-ok |
                      does\-ok | can\-ok | dies\-ok | lives\-ok |
                      eval\-dies\-ok | eval\-lives\-ok | throws\-like |
                      subtest
                    ]

                  / {
        if $l ~~ m:s/ ^ \s* subtest / {
          $!test-lines.push([ $lc, 's']);
        }

        elsif $l ~~ m:s/ ^ \s* throws\-like / {
          $!test-lines.push([ $lc, 't']);
        }

        else {
          $!test-lines.push([ $lc, 'n']);
        }
      }

      $lc++;
    }
note "TL: ", (map {"[$_]"}, @$!test-lines).join(',');

    # setup class
    my Str $class = 'test-block-code';
    if $!highlight-code {
      $class = "prettyprint $!highlight-language";
      $class ~= " linenums:$!line-number" if $!linenumbers;
    }

    # add the code text to the report document
    append-element( $parent, 'pre', {:$class}, :text($code-text));

    # also add a check part to the right side of the code block
    my Int $nlines = $code-text.lines.elems;
    my $aside-check = " \n" x $nlines;
    append-element(
      $parent, 'pre',
      { :class("aside-check"), :id("aside{$!line-number}nl{$nlines}")},
      :text($aside-check)
    );

    # insert a cleaner div below to prevent any disturbences of the two <pre>
    append-element( $parent, 'div', {:class('cleaner')});

    # update the line number count for the next code block
    $!line-number += $nlines;

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
  }

  #-----------------------------------------------------------------------------
  method !run-tests ( ) {

    # finish program and write to test file
    $!program-text ~= "\n\ndone-testing;\n";

    note "\nWrite test code to $!test-filename";
    $!test-filename.IO.spurt($!program-text);

    # run the tests using perl and get the result contents through a pipe
    note "\n---[ Prove output ]", '-' x 61;
    note " ";

    #'--timer', '--merge', "--archive $!test-filename.tgz",
    my Proc $p = run 'prove', '--exec', 'perl6', '--verbose',
                     '--ignore-exit', '--failures', "--rules='seq=**'",
                     '--nocolor', '--norc',
                     $!test-filename, :out, :err;

    # read lines from pipe from testing command
    my @lines = $p.out.lines;
    my @diag-lines = $p.err.lines;

#    $p.out.close;

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

note "Line : $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')], $line";

        # if indent increases, it could have been a subtest or a throws-like
        $indent = (~$/[0]).chars;
        if $indent > $prev-indent {
note "Indented... $test-lines-idx, $!test-lines[$test-lines-idx][1] (push)";
          if $!test-lines[$test-lines-idx][1] eq 's' {
            $idx-stack.push($test-lines-idx);

            # a subtest does show when decreasing indent. this line is the first
            # test in the subtest
note "Lin s: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')]";
            $test-lines-idx++;
            $!test-lines[$test-lines-idx].push(~$/[1]);
note "Lin x: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')], $line";
          }

          elsif $!test-lines[$test-lines-idx][1] eq 't' {
note "Lin t: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')]";

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
note "Compare $indent < $prev-indent (pop)";

          my $stack-idx = $idx-stack.pop;
          if $!test-lines[$test-lines-idx][1] eq 's' {
            $!test-lines[$stack-idx].push(~$/[1]);
          }

          elsif $!test-lines[$test-lines-idx][1] eq 't' {
            $!test-lines[$stack-idx].push(~$/[1]);
            $throws-like-test = False;
          }
note "End... $test-lines-idx, $stack-idx, \[$!test-lines[$stack-idx][*].join(',')]";

          #$test-lines-idx++;
          $prev-indent = $indent;
        }

        else {
          next if $throws-like-test;
          $!test-lines[$test-lines-idx].push(~$/[1]);
note "Lin n: $test-lines-idx, \[$!test-lines[$test-lines-idx][*].join(',')], $line";
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
  method !modify-aside-check-panels ( ) {

    my Int $test-lines-idx = 0;

    # search for the aside check panels
    my XML::Document $document .= new($!html);
    my $x = XML::XPath.new(:$document);
    for $x.find( '//pre', :to-list) -> $acheck {
      next unless $acheck.attribs<class> ~~ m/ 'aside-check' /;
      my $start-line = $acheck<id>;
      $start-line ~~ s/^ 'aside' //;
      my $nlines = $start-line;
      $start-line ~~ s/ 'nl' \d+ $//;
      $start-line .= Int;
      $nlines ~~ s/^ \d+ 'nl' //;
      $nlines .= Int;

      my @lines = [ ' ' xx $nlines ];
note "Init l: ", (map { "'$_'" }, @lines).join(', ');
      for $acheck.nodes -> $n {
        $n.remove;
      }

      loop ( my $i = 0; $i < $nlines; $i++) {
        next unless $!test-lines[$test-lines-idx].defined;
note "Loop: $start-line + $i, $test-lines-idx, $!test-lines[$test-lines-idx][0]";
        next unless ($start-line + $i) == $!test-lines[$test-lines-idx][0];

        @lines[$i] = $!test-lines[$test-lines-idx][2];
        $test-lines-idx++;
      }

note "\nLines aside: $start-line, $nlines, ", (map { "'$_'" }, @lines).join(', ');
      append-element( $acheck, :text(@lines.join("\n") ~ " \n"));
    }
  }
}
