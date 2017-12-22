use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<github:MARTIMM>;

use XML;
use XML::XPath;
use SemiXML::Sxml;
use SxmlLib::SxmlHelper;

#-------------------------------------------------------------------------------
class Summary {

  has $!sxml;

  has XML::Element $!html;
  has XML::Element $!body;

  has Bool $!initialized = False;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Sxml $!sxml, Hash $attrs ) {

    return if $!initialized;

#`{{
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
}}

#    $!run-data<title> = ($attrs<title>//'-').Str;
#    $!run-data<package> = ($attrs<package>//'-').Str;
#    $!run-data<class> = ($attrs<class>//'-').Str;
#    $!run-data<module> = ($attrs<module>//'-').Str;
#    $!run-data<distribution> = ($attrs<distribution>//'-').Str;
#    $!run-data<label> = ($attrs<label>//'-').Str;

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

#`{{
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
}}
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
#    $!body.set( 'onload', 'prettyPrint()') if $!highlight-code;

    # if there is a title attribute, make a h1 title
    append-element(
      $!body, 'h1', { id => '___top', class => 'title'},
      :text(~$attrs<title>)
    ) if ? $attrs<title>;
  }
}
