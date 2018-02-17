use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Sxml;
use SemiXML::Element;
use SxmlLib::File;

#-------------------------------------------------------------------------------
class Test {

  has SemiXML::Globals $!globals .= instance;

  has SemiXML::Element $!html;
  has SemiXML::Element $!body;

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

  enum Test-lines-entry < LINENUMBER TESTTYPE TESTRESULT CHAPTER
                          DIAGNOSTIC TODO SKIP
                        >;
  has Array $!test-lines = [];

  has Str $!chapter-test-title = 'No chapter test title';
  has Array $!chapters = [];
  has Str $!purpose-title = 'No purpose title';
  has Str $!purpose = "No purpose\n";

  has Hash $!run-data = {};

#TODO
#  bench marking
#  github issues
#  package version from META6.json when package attribute is used

  #-----------------------------------------------------------------------------
  method run ( SemiXML::Element $m ) {

    # setup the html and head
    self!initialize($m);

    # throw the whole shebang into the body
    $!body.after($_) for $m.nodes.reverse;

    # add the html to the parent
    $m.before($!html);

    self!modify-purpose;

    self!run-tests;
    self!save-metric-data;

    self!footer;
  }

  #-----------------------------------------------------------------------------
  method purpose ( SemiXML::Element $m ) {

    # save the title. purpose content is saved later
    $!purpose-title = ($m.attributes<title>//$!purpose-title).Str;

    my SemiXML::Element $div .= new(
      :name<div>, :attributes({:class<repsection>})
    );
    $m.before($div);
    $div.append(
      'h2', :attributes({:class<repheader>}), :text($!purpose-title)
    );

    my XML::Element $p = $div.append( 'p', :attributes({:title<purpose>}));
    $p.insert($_) for $m.nodes.reverse;
  }

  #-----------------------------------------------------------------------------
  method chapter ( SemiXML::Element $m ) {

    $!chapter-test-title = ($m.attributes<title>//'No test title').Str;
    $!chapters.push($!chapter-test-title);

    # search for the aside check panels, xpath '//pre'
    my Array $r $m.search([SCRootDesc, 'pre']);
    for @$r -> $acheck {

      # skip if <pre> is not an aside check
      if $acheck.attributes<class>:exists
         and $acheck.attributes<class> ~~ m/ 'aside-check' / {
        $acheck.set( 'title', $!chapter-test-title);
      }

      # or a diagnostic panel
      elsif $acheck.attributes<name>:exists
        and $acheck.attributes<name> eq 'diagnostic' {
        $acheck.set( 'title', $!chapter-test-title);
      }
    }

    my SemiXML::Element $div .= new(
      :name<div>, :attributes({:class<repsection>})
    );
    $m.before($div);

    $div.insert($_) for $m.nodes.reverse;
    $div.insert(
      'h2', :attributes({:class<repheader>}), :text($!chapter-test-title)
    );
  }

  #-----------------------------------------------------------------------------
  method code ( SemiXML::Element $m ) {
    self!wrap-code( $m, :type<code>);
  }

  #-----------------------------------------------------------------------------
  method skip ( SemiXML::Element $m ) {
    self!wrap-code( $m, :type<skip>);
  }

  #-----------------------------------------------------------------------------
  method todo ( SemiXML::Element $m ) {
    self!wrap-code( $m, :type<todo>);
  }

  #===[ private methods ]=======================================================
  method !initialize ( SemiXML::Element $m ) {

    return if $!initialized;

    # things to highlight code using google prettify
    $!highlight-code = ($m.attributes<lang> // '').Str.Bool;
    $!language = $!highlight-language = ($m.attributes<lang> // 'perl6').Str;
    $!highlight-skin = lc(($m.attributes<highlight-skin> // 'prettify').Str);
    $!highlight-skin = 'prettify' if $!highlight-skin eq 'default';
    $!linenumbers = ($m.attributes<linenumbers> // '').Str.Bool;

    # start of perl6 test code data. starting linenumeber is set to 4
    $!program-text = Q:to/EOINIT/;
      use v6;
      use Test;
      #use MONKEY-SEE-NO-EVAL;

      EOINIT
    $!line-number = 5;

    # test information
    $!test-filename = $!globals.filename;
    $!test-filename ~~ s/ '.sxml' $/.t/;
#TODO
# attribute test command to support other languages
# attribute location of generated test file

#    $!run-data<test-location> = ($m.attributes<test-location>//'.').Str;
#    $!run-data<test-program> = ($m.attributes<test-program>//'prove').Str;
#    $!run-data<test-options> = ($m.attributes<test-options>//(
#        '--exec', 'perl6', '--verbose',
#        '--ignore-exit', '--failures', "--rules='seq=**'",
#        '--nocolor', '--norc',
#      )
#    ).List;

#TODO add type of test; Smoke tests, System integration tests, Regression tests

    # title of test report
    $!run-data<title> = ($m.attributes<title>//'-').Str;

    # extra information for metric file
    $!run-data<package> = ($m.attributes<package>//'-').Str;
    $!run-data<class> = ($m.attributes<class>//'-').Str;
    $!run-data<module> = ($m.attributes<module>//'-').Str;
    $!run-data<distribution> = ($m.attributes<distribution>//'-').Str;
    $!run-data<label> = ($m.attributes<label>//'-').Str;


    self!initialize-report($m.attributes);
    $!initialized = True;
  }

  #-----------------------------------------------------------------------------
  method !initialize-report ( Hash $attrs ) {

#`{{
    $!html .= new(
      :name<html>, :attribs(
        xmlns => 'http://www.w3.org/199/xhtml', 'xml:lang' => 'en'
      )
    );
}}

    $!html .= new( :name<html>, :attribs('xml:lang' => 'en'));
    #my SemiXML::Element $head = self!head( $!html, $attrs);
    self!head($attrs);
    self!body( $!html, $attrs);
  }

  #-----------------------------------------------------------------------------
  method !head ( Hash $attrs --> SemiXML::Element ) {

    my SemiXML::Element $head = $html.append-element( $!html, 'head');
    append-element( $head, 'title', :text(~$attrs<title>)) if ? $attrs<title>;
    append-element( $head, 'meta', {charset => 'UTF-8'});
    append-element(
      $head, 'meta', { :name<description>, content => 'Test report'}
    );
    append-element(
      $head, 'meta', { :name<keywords>, content => 'sxml report test'}
    );
    append-element(
      $head, 'meta', { 'http-equiv' => "language", :content<EN>}
    );

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

#`{{
    my $css = %?RESOURCES<report.css>.Str;
    append-element(
      $head, 'link', {
        :href("file://$css"),
        :type<text/css>, :rel<stylesheet>
      }
    );
}}
    my SxmlLib::File $sf .= new;
    $sf.include(
      $head, {
        :type<include-xml>,
        :reference(%?RESOURCES<test-report-style.xml>.Str)
      }
    );

    $head
  }

  #-----------------------------------------------------------------------------
  method !body ( XML::Element $html, Hash $attrs ) {
    $!body = append-element( $html, 'body');
    $!body.set( 'onload', 'prettyPrint()') if $!highlight-code;

#`{{
    # if there is a title attribute, make a h1 title
    append-element(
      $!body, 'h1', { id => '___top', class => 'title'},
      :text(~$attrs<title>)
    ) if ? $attrs<title>;
}}

    if ? $attrs<title> {
      my XML::Element $t = append-element(
        $!body, 'div', {class => 'title'}
      );

      append-element(
        $t, 'h1', {class => 'title-text'},
        :text(~$attrs<title>)
      );
    }

  }



#`{{
    # Experiment to wrap all in EVALs
    $code-text ~~ s:g/ ( \n \s* ['is'||'isnt'||'is-deeply'||'is-approx'||'like'||'unlike'||'cmp-ok'||'ok'||'nok'] '('? \s+ )
                       ( <-[,]>* ) ( <-[;]>* )
                     /$/[0]EVAL\('try {$/[1]}'\)$/[2]; note \$! if ? \$!/;
note $code-text;
}}

  #-----------------------------------------------------------------------------
  # modify the purpose to show what is tested and what is not
  method !modify-purpose ( ) {

    # search for the aside check panels
    my XML::Document $document .= new($!body);
    my $x = XML::XPath.new(:$document);

    # should only be one purpose
    my XML::Element $purpose = $x.find( '//p[@title="purpose"]', :to-list)[0];
    return unless $purpose.defined;

    # add a paragraph below the users text and add the chapters to a list
    append-element(
      $purpose, 'p',
      :text('The tests comprises the following chapters')
    );
    my XML::Element $ul = append-element( $purpose, 'ul');
    append-element( $ul, 'li', :text($_)) for @$!chapters;

    $!purpose = ~$purpose;
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

  #-----------------------------------------------------------------------------
  method !wrap-code ( SemiXML::Element $m, :$type ) {

    # get code text from code element
    my Str $code-text = self!get-code-text($m);

    # wrap in a subtest if a title attribute is found
    $code-text = self!wrap-subtest( $code-text, $m.attributes);

    # add some code depending on code type
    $code-text = self!wrap-type( $type, $code-text, $m.attributes);

    # gather the line numbers where the tests are written
    self!save-testlines($code-text);

    # insert place to display the code
    $m.before(self!create-code-element($code-text));

    # insert place to display the test results
    $m.before(self!create-test-result($code-text));

    # insert a cleaner div below to prevent any disturbences of the two <pre>
    $m.before( SemiXML::Element.new(
        :name<pre>, :attributes({ :class<cleaner>, :name<diagnostic>})
      )
    );

    # add to total code text to be run later
    $!program-text ~= $code-text;
  }

  #-----------------------------------------------------------------------------
  method !get-code-text ( SemiXML::Element $code --> Str ) {

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
  method !create-code-element( $code-text --> SemiXML::Element ) {

    # setup class
    my Str $class = 'test-block-code';
    if $!highlight-code {
      $class = "prettyprint $!highlight-language";
      $class ~= " linenums:$!line-number" if $!linenumbers;
    }

    # add the code text to the report document
    SemiXML::Element.new(
      :name<pre>, :attributes({:$class}), :text($code-text)
    )
  }

  #-----------------------------------------------------------------------------
  # create <pre> element to show diagnostic info
  method !create-test-result( $code-text --> SemiXML::Element ) {

    my Int $nlines = $code-text.lines.elems;
    my $aside-check = " \n" x $nlines;
    my SemiXML::Element $pre .= new(
      :name<pre>,
      :attributes( {
          :class("aside-check"),
          :name("aside{$!line-number}nl{$nlines}"),
          :title('No test title')
        }
      ),
      :text($aside-check)
    );

    # update the line number count for the next code block
    $!line-number += $nlines;

    $pre
  }

  #-----------------------------------------------------------------------------
  method !run-tests ( ) {

#note "TL: ", (map { "[$_]" }, @$!test-lines).join(', ');

    note "\n---[ Prove output ]", '-' x 61;
    note " ";

    # run the tests
    my Array $result-lines = self!get-test-result;
    my @lines = |$result-lines[0];
    my @diag-lines = |$result-lines[1];
    my @diag = @diag-lines;

    # interprete test results
    my Int $indent = 0;
    my Int $prev-indent = 0;
    my Int $test-lines-idx = 0;
    my Bool $throws-like-test = False;
    my Array $idx-stack = [];

    for @lines -> $line {
      my $message = $line;
      $message ~~ s/^ \s* //;
      $line ~~ /^ (\s*) (['not' \s+]? 'ok') /;

      if $/.defined {
        note $line;

        # stick to the last one if w've gone too far
        $test-lines-idx -= 1 unless $!test-lines[$test-lines-idx].defined;

#note "Line : $test-lines-idx, \[$!test-lines[$test-lines-idx][0,1].join(',')], $message";

        # if indent increases, it could have been a subtest or a throws-like
        $indent = (~$/[0]).chars;
        if $indent > $prev-indent {
#note "Indented...";
          if $!test-lines[$test-lines-idx][TESTTYPE] eq 's' {
            $idx-stack.push($test-lines-idx);

            # a subtest does show when decreasing indent. this line is the first
            # test in the subtest
#note ">>> s: $test-lines-idx, \[$!test-lines[$test-lines-idx][0..1].join(',')]";
            $test-lines-idx++;
            self!store-state( $!test-lines[$test-lines-idx], ~$/[1], $message, @diag);
#note ">>> x: $test-lines-idx, \[$!test-lines[$test-lines-idx][0..2].join(',')], $message";
          }

          elsif $!test-lines[$test-lines-idx][TESTTYPE] eq 't' {
#note ">>> t: $test-lines-idx, \[$!test-lines[$test-lines-idx][0,1].join(',')]";

            $idx-stack.push($test-lines-idx);
            $throws-like-test = True;
          }

          # set todo or skip state
          $!test-lines[$test-lines-idx][TODO] = ?($message ~~ /:s TODO /);
          $!test-lines[$test-lines-idx][SKIP] = ?($message ~~ /:s SKIP /);
          $test-lines-idx++;
          $prev-indent = $indent;
        }

        # if indent decreases, it could have been the
        # end of a subtest or a throws-like
        elsif $indent < $prev-indent {
#note "Outdented...";

          my $stack-idx = $idx-stack.pop;
          if $!test-lines[$stack-idx][TESTTYPE] eq 's' {
            self!store-state( $!test-lines[$stack-idx], ~$/[1], $message, @diag);
            #$!test-lines[$stack-idx][TESTRESULT] = ~$/[1];
            #$!test-lines[$stack-idx][DIAGNOSTIC] = "$message\n";
            #if $!test-lines[$stack-idx][TESTRESULT] ~~ /:s not ok/ {
            #  self!gather-diagnostic( @diag, $!test-lines[$stack-idx]);
            #}
#note "<<< s: $test-lines-idx, \[$!test-lines[$stack-idx][0..2].join(',')]";
          }

          elsif $!test-lines[$stack-idx][TESTTYPE] eq 't' {
            self!store-state( $!test-lines[$stack-idx], ~$/[1], $message, @diag);
            #$!test-lines[$stack-idx][TESTRESULT] = ~$/[1];
            #$!test-lines[$stack-idx][DIAGNOSTIC] = "$message\n";
            #if $!test-lines[$stack-idx][TESTRESULT] ~~ /:s not ok/ {
            #  self!gather-diagnostic( @diag, $!test-lines[$stack-idx]);
            #}
            $throws-like-test = False;
#note "<<< t: $test-lines-idx, \[$!test-lines[$stack-idx][0..2].join(',')]";
          }

          # set todo or skip state
          $!test-lines[$test-lines-idx][TODO] = ?($message ~~ /:s TODO /);
          $!test-lines[$test-lines-idx][SKIP] = ?($message ~~ /:s SKIP /);
          $prev-indent = $indent;
        }

        else {
          next if $throws-like-test;
          self!store-state( $!test-lines[$test-lines-idx], ~$/[1], $message, @diag);
          #$!test-lines[$test-lines-idx][TESTRESULT] = ~$/[1];
          #$!test-lines[$test-lines-idx][DIAGNOSTIC] = "$message\n";
          #if $!test-lines[$test-lines-idx][TESTRESULT] ~~ /:s not ok/ {
          #  self!gather-diagnostic( @diag, $!test-lines[$test-lines-idx]);
          #}
#note "    n: $test-lines-idx, \[$!test-lines[$test-lines-idx][0..2].join(',')], $message";

          # set todo or skip state
          $!test-lines[$test-lines-idx][TODO] = ?($message ~~ /:s TODO /);
          $!test-lines[$test-lines-idx][SKIP] = ?($message ~~ /:s SKIP /);
          $test-lines-idx++;
        }
      }
    }

    note "\n---[ End prove output ]", '-' x 57;
    note " ";
    .note for @diag-lines;
    note "\n---[ End prove diagnostics ]", '-' x 52;
    note " ";

    self!modify-aside-check-panels;
    self!modify-diagnostic-panel(@diag-lines);
  }

  #-----------------------------------------------------------------------------
  method !store-state (
    Array $test-line, Str $status, Str $message, @diag
  ) {

    $test-line[TESTRESULT] = $status;
    $test-line[DIAGNOSTIC] = "$message\n";

    if $test-line[TESTRESULT] ~~ /:s not ok/ {
      self!gather-diagnostic( @diag, $test-line);
    }
  }

  #-----------------------------------------------------------------------------
  method !gather-diagnostic ( @diag, Array $test-line ) {

    $test-line[DIAGNOSTIC] //= '';

    repeat {

      # check if there are still diagnostic messages
      last unless @diag.elems;

      # get a diagnostic line and calculate indent
      my $dline = @diag.shift;

      # remove indent and '#'
      $dline ~~ s/^ \s* '#' \s+ //;

      # save and add a newline
      $test-line[DIAGNOSTIC] ~= $dline ~ "\n";
    } until @diag.elems == 0 or @diag[0] ~~ /:s Failed test || Looks like /;

    # if type is a throws-like then read another line
    if @diag.elems and $test-line[TESTTYPE] eq 't' {
      my $dline = @diag.shift;
      if $dline ~~ /:s Looks like you failed/ {
        $dline ~~ s/^ \s* '#' \s+ //;
        $test-line[DIAGNOSTIC] ~= $dline ~ "\n";
      }

      # look for further messages from a level higher
      repeat {
        last unless @diag.elems;
        my $dline = @diag.shift;
        $dline ~~ s/^ \s* '#' \s+ //;
        $test-line[DIAGNOSTIC] ~= $dline ~ "\n";
      } until @diag.elems == 0 or @diag[0] ~~ /:s Failed test || Looks like /;
    }

    # if type is a subtest then read another line
    if @diag.elems and $test-line[TESTTYPE] eq 's' {
      my $dline = @diag.shift;
      $dline ~~ s/^ \s* '#' \s+ //;
      $test-line[DIAGNOSTIC] ~= $dline ~ "\n";

      # if this was a plan failure then read another line
      if @diag.elems and $dline ~~ /:s Looks like you planned/ {
        $dline = @diag.shift;
        $dline ~~ s/^ \s* '#' \s+ //;
        $test-line[DIAGNOSTIC] ~= $dline ~ "\n";
      }

      # look for further messages from a level higher
      repeat {
        last unless @diag.elems;
        my $dline = @diag.shift;
        $dline ~~ s/^ \s* '#' \s+ //;
        $test-line[DIAGNOSTIC] ~= $dline ~ "\n";
      } until @diag.elems == 0 or @diag[0] ~~ /:s Failed test || Looks like /;
    }
  }

  #-----------------------------------------------------------------------------
  # run the tests using perl5 prove and get the result lines
  method !get-test-result ( --> Array ) {

    # finish program and write to test file
    $!program-text ~= "\n\ndone-testing;\n";
    $!test-filename.IO.spurt($!program-text);

    #$!run-data<test-location>

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

    state Int $counter = 1;
    my Int $test-lines-idx = 0;

    # search for the aside check panels
    my XML::Document $document .= new($!html);
    my $x = XML::XPath.new(:$document);
    for $x.find( '//pre[@class="aside-check"]', :to-list) -> $acheck {

      # get start line number and the number of line in the aside
      my $start-line = $acheck<name>;
      $start-line ~~ s/^ 'aside' //;
      my $nlines = $start-line;
      $start-line ~~ s/ 'nl' \d+ $//;
      $start-line .= Int;
      $nlines ~~ s/^ \d+ 'nl' //;
      $nlines .= Int;

      # get chapter title
      my $chapter = $acheck<title>;

      # empty the aside <pre> element
      for $acheck.nodes -> $n {
        $n.remove;
      }

      # loop over the test lines and set the results from the tests
      loop ( my $i = 0; $i < $nlines; $i++) {

        # check if there are still test lines left
        if $!test-lines[$test-lines-idx].defined {

          # check if line count matches the test-lines number
          if ($start-line + $i) == $!test-lines[$test-lines-idx][LINENUMBER] {

            my Str $mark-symbol;
            my Str $class;
            if $!test-lines[$test-lines-idx][TESTRESULT] ~~ /:s not ok/ {
              $class = $!test-lines[$test-lines-idx][TODO] ?? 'orange' !! 'red';
              $class = $!test-lines[$test-lines-idx][SKIP] ?? 'purple' !! 'red';
              if $!test-lines[$test-lines-idx][TESTTYPE] eq 's' {
                $mark-symbol = "\x[1F5D0]($counter)";
              }

              else {
                $mark-symbol = "\x[2718]($counter)";
              }

              $counter++;
            }

            else {
              $class = $!test-lines[$test-lines-idx][TODO] ?? 'orange' !! 'green';
              $class = $!test-lines[$test-lines-idx][SKIP] ?? 'purple' !! 'green';
              #$class = 'green';
              $mark-symbol = "\x[2713]";
            }

            append-element(
              #$acheck, 'span', {:$class}, :text($mark-symbol ~ "\n")
              $acheck, 'div', {:$class}, :text($mark-symbol ~ "\n")
            );

            # add chapter to the test lines
            $!test-lines[$test-lines-idx][CHAPTER] = $chapter;

            # on to the next test
            $test-lines-idx++;
          }

          else {
            #append-element( $acheck, 'span', :text("\n"));
            append-element( $acheck, 'div', :text("\n"));
          }
        }

        # fill last lines up
        else {
          #append-element( $acheck, 'span', :text("\n"));
          append-element( $acheck, 'div', :text("\n"));
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  method !modify-diagnostic-panel ( @diag-lines ) {

    my @diag = @diag-lines;
    state Int $counter = 1;

    my Int $test-lines-idx = 0;
    my Str $diag-title = $!test-lines[$test-lines-idx][CHAPTER] // '-';

    # search for the aside check panels
    my XML::Document $document .= new($!html);
    my $x = XML::XPath.new(:$document);

    my @diag-panels = $x.find( '//pre[@name="diagnostic"]', :to-list);
    loop ( my $i = 0; $i < @diag-panels.elems; $i++) {
      my XML::Element $diag-panel = @diag-panels[$i];

      # skip if <pre> is not a diagnostic
      if $diag-panel.attribs<name>:exists
         and $diag-panel.attribs<name> eq 'diagnostic' {

        # move to the next panel if the next still has the same title
        next if @diag-panels[$i+1].defined
                and $diag-title eq @diag-panels[$i+1].attribs<title>;

        # test the title of the panel against that of the test-lines
        while $diag-title eq $diag-panel.attribs<title> {

          if $!test-lines[$test-lines-idx][TESTRESULT] ~~ /:s not ok/ {

            my Str $mark = "$counter  ";

            if $!test-lines[$test-lines-idx].defined
               and $!test-lines[$test-lines-idx][TESTTYPE] eq 't' {

              $mark = "{$counter} ";
              self!add-to-diag-panel( $diag-panel, @diag, $mark, $test-lines-idx);
            }

            else {
              self!add-to-diag-panel( $diag-panel, @diag, $mark, $test-lines-idx);
            }

            $diag-panel.set( 'style', 'border-width:2px;');
            $counter++;
          }

          $test-lines-idx++;
          last unless @diag.lines
               and $!test-lines[$test-lines-idx].defined;
          $diag-title = $!test-lines[$test-lines-idx][CHAPTER];
        }
      }

      else {
        note 'Pre: ', ~$diag-panel;
      }
    }
  }

  #-----------------------------------------------------------------------------
  method !add-to-diag-panel (
    $diag-panel, @diag, Str $mark is copy, Int $test-lines-idx
  ) {

    my Str $s = $mark ~ $!test-lines[$test-lines-idx][DIAGNOSTIC];
    my @lines = $s.lines;
    $s = @lines.shift ~ "\n";
    $s ~~ s:g/\s\s+/ /;
    append-element( $diag-panel, 'strong', :text($s));
    append-element( $diag-panel, :text(.indent(2) ~ "\n")) for @lines;
  }

  #-----------------------------------------------------------------------------
  method !save-metric-data ( ) {

    # metric filename
    my $c = $*PERL.compiler();
    my $metric-file = $!globals.refined-tables<S><rootpath> ~
                      '/' ~ $!globals.filename.IO.basename;
    $metric-file ~~ s/\.sxml $/-metric/;
    $metric-file ~= [~] "-$*DISTRO.name()", "-$*DISTRO.version()", ".toml";

    # general metric content
    my Str $metric-text = "[ general ]\n";

    # gather data from attributes
    $metric-text ~= "  title        = '$!run-data<title>'\n";
    $metric-text ~= "  package      = '$!run-data<package>'\n";
    $metric-text ~= "  module       = '$!run-data<module>'\n";
    $metric-text ~= "  class        = '$!run-data<class>'\n";
    $metric-text ~= "  distribution = '$!run-data<distribution>'\n";
    $metric-text ~= "  label        = '$!run-data<label>'\n";

    $metric-text ~= "  date         = '" ~ now.DateTime.utc.Str ~ "'\n";

    # gather data from compiler and system
    $metric-text ~= "  oskernel     = '$*KERNEL.name():$*KERNEL.version()'\n";
    $metric-text ~= "  osdistro     = '$*DISTRO.name():$*DISTRO.version():$*DISTRO.release():$*DISTRO.is-win()'\n";
    $metric-text ~= "  perl         = '$*PERL.name():$*PERL.version()'\n";
    $metric-text ~= "  compiler     = '$c.name():$c.version()'\n";
    $metric-text ~= "  vm           = '$*VM.name():$*VM.version()'\n";

    $metric-text ~= "\n[ purpose ]\n";
    $metric-text ~= "  purposetitle = '$!purpose-title'\n";
    $metric-text ~= "  purpose      = '''\n$!purpose\n'''\n";

    $metric-text ~= "\n[ chapters ]\n";
    $metric-text ~= "  list         = [ { (map { "'$_'" }, @$!chapters).join(', ') } ]\n";

    # chapters
    my Str $chapter = '';
    my Int $chapter-count = 1;

    my Int $success = 0;
    my Int $fail = 0;
    my Int $todo = 0;
    my Int $skip = 0;

    # go through the tests
    for @$!test-lines -> $test-line {
      if $test-line[CHAPTER] ne $chapter {

        # write totals of previous chapter
        if ? $chapter {
          $metric-text ~= "  success      = $success\n";
          $metric-text ~= "  fail         = $fail\n";
          $metric-text ~= "  todo         = $todo\n";
          $metric-text ~= "  skipped      = $skip\n";

          # reset
          $success = 0;
          $fail = 0;
          $todo = 0;
          $skip = 0;
        }

        # next chapter
        my $toml-text = $test-line[CHAPTER];
        $toml-text ~~ s:g/\'//;
        $metric-text ~= "\n[ chapter.'$toml-text' ]\n";
        $chapter = $test-line[CHAPTER];
        $chapter-count++;
      }

      # count results.
      # skip subtest count because that's a result from inner tests
      if $test-line[TESTTYPE] ne 's' {
        if $test-line[SKIP] {
          $skip++;
        }

        elsif $test-line[TODO] {
          $todo++;
        }

        elsif $test-line[TESTRESULT] ~~ /:s not ok / {
          $fail++;
        }

        else {
          $success++;
        }
      }
    }

    # last chapters data
    $metric-text ~= "  success      = $success\n";
    $metric-text ~= "  fail         = $fail\n";
    $metric-text ~= "  todo         = $todo\n";
    $metric-text ~= "  skipped      = $skip\n";

    # summary of all failure messages
    for @$!test-lines -> $test-line {
      $metric-text ~= "\n[ summary.line-$test-line[LINENUMBER] ]\n";
      $metric-text ~= "  chapter      = '$test-line[CHAPTER]'\n";
      $metric-text ~= "  diagnostic   = \"\"\"\n$test-line[DIAGNOSTIC].indent(4)\"\"\"\n";
    }

    # save all metric data
    note "Saved metrics in $metric-file"
      if $!globals.trace and $!globals.refined-tables<T><file-handling>;
    $metric-file.IO.spurt($metric-text);
  }
}
