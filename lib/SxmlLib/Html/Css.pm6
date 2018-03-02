use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Node;
use SemiXML::Element;
use SemiXML::Text;

#-------------------------------------------------------------------------------
# Stylesheet manipulations
class Html::Css {

  has SemiXML::Element $!style;
  has Bool $!initialized = False;

  #-----------------------------------------------------------------------------
#TODO stylesheets can be used in xml docs other than html
  method initialize ( SemiXML::Element $m ) {

    return if $!initialized;

    $!style .= new(
      :name<style>, :attributes({'sxml:noconv' => '1'}),
      :text("\n")
    );
    $!style.noconv = True;

    my Array $r = $m.search( [
        SemiXML::SCRoot, 'html', SemiXML::SCChild, 'head',
        SemiXML::SCChild, 'style'
      ]
    );

    if $r.elems {
      # place style after the last one
      $r[*-1].after($!style);
    }

    # no style found add to the end of head
    else {
      $r = $m.search( [ SemiXML::SCRoot, 'html', SemiXML::SCChild, 'head']);
      if $r.elems {
        $r[0].append($!style);
      }

      else {
        die 'Css must be placed in /html/head but head is not found';
      }
    }

    $!initialized = True;
  }

  #-----------------------------------------------------------------------------
  #https://perishablepress.com/a-killer-collection-of-global-css-reset-styles/
  method reset ( SemiXML::Element $m ) {

    my Str $type = ($m.attributes<type>//'minimalistic').Str;
    given $type {
      when 'minimalistic' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            * {
            	outline: 0;
            	padding: 0;
            	margin: 0;
            	border: 0;
          	}
            EOCSS
      }

      when 'condensed-universal' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            * {
            	vertical-align: baseline;
            	font-weight: inherit;
            	font-family: inherit;
            	font-style: inherit;
            	font-size: 100%;
            	border: 0 none;
            	outline: 0;
            	padding: 0;
            	margin: 0;
          	}
            EOCSS
      }

      when 'poor-man' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)))
            html, body {
            	padding: 0;
            	margin: 0;
            }
            html {
            	font-size: 1em;
            }
            body {
            	font-size: 100%;
            }
            a img, :link img, :visited img {
            	border: 0;
            }
            EOCSS
      }

      when 'siolon-global' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            * {
            	vertical-align: baseline;
            	font-family: inherit;
            	font-style: inherit;
            	font-size: 100%;
            	border: none;
            	padding: 0;
            	margin: 0;
            }
            body {
            	padding: 5px;
            }
            h1, h2, h3, h4, h5, h6, p, pre, blockquote, form, ul, ol, dl {
            	margin: 20px 0;
            }
            li, dd, blockquote {
            	margin-left: 40px;
            }
            table {
            	border-collapse: collapse;
            	border-spacing: 0;
          	}
            EOCSS
      }

      when 'shaun-inman' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            body, div, dl, dt, dd, ul, ol, li, h1, h2, h3, h4, h5, h6, pre,
            form, fieldset, input, p, blockquote, table, th, td, embed, object {
            	padding: 0;
            	margin: 0;
            }
            table {
            	border-collapse: collapse;
            	border-spacing: 0;
            }
            fieldset, img, abbr {
            	border: 0;
            }
            address, caption, cite, code, dfn, em,
            h1, h2, h3, h4, h5, h6, strong, th, var {
            	font-weight: normal;
            	font-style: normal;
            }
            ul {
            	list-style: none;
            }
            caption, th {
            	text-align: left;
            }
            h1, h2, h3, h4, h5, h6 {
            	font-size: 1.0em;
            }
            q:before, q:after {
            	content: '';
            }
            a, ins {
            	text-decoration: none;
          	}
            EOCSS
      }

      when 'yahoo' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            body,div,dl,dt,dd,ul,ol,li,h1,h2,h3,h4,h5,h6,pre,form,fieldset,input,textarea,p,blockquote,th,td {
            	padding: 0;
            	margin: 0;
            }
            table {
            	border-collapse: collapse;
            	border-spacing: 0;
            }
            fieldset,img {
            	border: 0;
            }
            address,caption,cite,code,dfn,em,strong,th,var {
            	font-weight: normal;
            	font-style: normal;
            }
            ol,ul {
            	list-style: none;
            }
            caption,th {
            	text-align: left;
            }
            h1,h2,h3,h4,h5,h6 {
            	font-weight: normal;
            	font-size: 100%;
            }
            q:before,q:after {
            	content:'';
            }
            abbr,acronym {
              border: 0;
            }
            EOCSS
      }

      when 'eric-meyer' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            html, body, div, span, applet, object, iframe, table, caption, tbody, tfoot, thead, tr, th, td,
            del, dfn, em, font, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var,
            h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code,
            dl, dt, dd, ol, ul, li, fieldset, form, label, legend {
            	vertical-align: baseline;
            	font-family: inherit;
            	font-weight: inherit;
            	font-style: inherit;
            	font-size: 100%;
            	outline: 0;
            	padding: 0;
            	margin: 0;
            	border: 0;
            }
            /* remember to define focus styles! */
            :focus {
            	outline: 0;
            }
            body {
            	background: white;
            	line-height: 1;
            	color: black;
            }
            ol, ul {
            	list-style: none;
            }
            /* tables still need cellspacing="0" in the markup */
            table {
            	border-collapse: separate;
            	border-spacing: 0;
            }
            caption, th, td {
            	font-weight: normal;
            	text-align: left;
            }
            /* remove possible quote marks (") from <q> & <blockquote> */
            blockquote:before, blockquote:after, q:before, q:after {
            	content: "";
            }
            blockquote, q {
            	quotes: "" "";
            }
            EOCSS
      }

      when 'eric-meyer-condensed' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            body, div, dl, dt, dd, ul, ol, li, h1, h2, h3, h4, h5, h6,
            pre, form, fieldset, input, textarea, p, blockquote, th, td {
            	padding: 0;
            	margin: 0;
            }
            fieldset, img {
            	border: 0;
            }
            table {
            	border-collapse: collapse;
            	border-spacing: 0;
            }
            ol, ul {
            	list-style: none;
            }
            address, caption, cite, code, dfn, em, strong, th, var {
            	font-weight: normal;
            	font-style: normal;
            }
            caption, th {
            	text-align: left;
            }
            h1, h2, h3, h4, h5, h6 {
            	font-weight: normal;
            	font-size: 100%;
            }
            q:before, q:after {
            	content: '';
            }
            abbr, acronym {
            	border: 0;
            }
            EOCSS
      }

      when 'tantek' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            /* undohtml.css */
            /* (CC) 2004 Tantek Celik. Some Rights Reserved.                  */
            /* http://creativecommons.org/licenses/by/2.0                     */
            /* This style sheet is licensed under a Creative Commons License. */

            :link, :visited {
            	text-decoration: none;
            }
            ul, ol {
            	list-style: none;
            }
            h1, h2, h3, h4, h5, h6, pre, code, p {
            	font-size: 1em;
            }
            ul, ol, dl, li, dt, dd, h1, h2, h3, h4, h5, h6, pre,
            form, body, html, p, blockquote, fieldset, input {
            	padding: 0;
            	margin: 0;
            }
            a img, :link img, :visited img {
            	border: none;
            }
            address {
            	font-style: normal;
          	}
            EOCSS
      }

      when 'tripoli' {
        $!style.append(SemiXML::Text.new(:text(q:to/EOCSS/)));
            /*
                Tripoli is a generic CSS standard for HTML rendering.
                Copyright (C) 2007  David Hellsing

                This program is free software: you can redistribute it and/or modify
                it under the terms of the GNU General Public License as published by
                the Free Software Foundation, either version 3 of the License, or
                (at your option) any later version.

                See also http://www.gnu.org/licenses/
            */
            * {
            	text-decoration: none;
            	font-size: 1em;
            	outline: none;
            	padding: 0;
            	margin: 0;
            }
            code, kbd, samp, pre, tt, var, textarea,
            input, select, isindex, listing, xmp, plaintext {
            	white-space: normal;
            	font-size: 1em;
            	font: inherit;
            }
            dfn, i, cite, var, address, em {
            	font-style: normal;
            }
            th, b, strong, h1, h2, h3, h4, h5, h6 {
            	font-weight: normal;
            }
            a, img, a img, iframe, form, fieldset,
            abbr, acronym, object, applet, table {
            	border: none;
            }
            table {
            	border-collapse: collapse;
            	border-spacing: 0;
            }
            caption, th, td, center {
            	vertical-align: top;
            	text-align: left;
            }
            body {
            	background: white;
            	line-height: 1;
            	color: black;
            }
            q {
            	quotes: none;
            }
            ul, ol, dir, menu {
            	list-style: none;
            }
            sub, sup {
            	vertical-align: baseline;
            }
            a {
            	color: inherit;
            }
            hr {
            	display: none;
            }
            font {
            	color: inherit !important;
            	font: inherit !important;
            	color: inherit !important; /* editor's note: necessary? */
            }
            marquee {
            	overflow: inherit !important;
            	-moz-binding: none;
            }
            blink {
            	text-decoration: none;
            }
            nobr {
            	white-space: normal;
            }
            EOCSS
      }
    }

    # work is done, next time init again
    $!initialized = False;
  }

  #-----------------------------------------------------------------------------
  method style ( SemiXML::Element $m ) {

#note "\nStyle 0:\n$m\n\n$!style";

    for $m.nodes.reverse -> $node {
      $!style.insert($node) if $node.name ne 'sxml:css-block';
    }

    self!css-blocks( $m, '');
#note "\nStyle 1:\n$!style";

    # work is done, next time init again
    $!initialized = False;
  }

  #-----------------------------------------------------------------------------
  method b ( SemiXML::Element $m ) {

    my Str $selector = ($m.attributes<s>//'*').Str;
    my SemiXML::Element $css-block .= new(
      :name<sxml:css-block>,
      :attributes({s => $selector})
    );

    $css-block.insert($_) for $m.nodes.reverse;
    $m.before($css-block);
  }

  #-----------------------------------------------------------------------------
  #---[ private ]---------------------------------------------------------------
#TODO Convert text content of each block to key/value from "'key' : 'value' ;".
# Store in a Hash to remove older entries automatically. An array of keys can
# be used to keep same sequence as entered. If possible check with current
# defaults to see if it can be left out.

  method !css-blocks (
    SemiXML::Node $css-block, Str $parent-select, Array $block-content = []
  ) {
#note "Style xml: ", $css-block.nodes>>.xml.join(' ');

    my Array $css-bodies = [|$block-content];

    # build current selector
    my Str $select = '';

    # check if it is a sxml:css-block and has an 's' attribute.
    my Bool $is-block =
          ( ($css-block.name eq 'sxml:css-block')
             and ($css-block.attributes<s>:exists)
          );

    # insert a separator blank if parent css block selector is defined
    if $is-block {
      $select = [~] $parent-select,
                    (?$parent-select ?? ' ' !! ''),
                    $css-block.attributes<s>;
    }

    # do the textual parts first, then process rest
    for $css-block.nodes -> $node {
      if $node.name eq 'sxml:css-block' {
        self!css-blocks( $node, $select, $css-bodies);
      }

      else {
        $css-bodies.push: $node;
      }
    }

    # if the css body is not a string of only spaces, add it to the style
    if $is-block and ([~] @$css-bodies) !~~ m/^ \s* $/ {

      if [~] @$css-bodies ~~ m/ \S / {
        $!style.append(:text("\n$select \{\n  "));
        $!style.append(.clone-node) for @$css-bodies;
        $!style.append(:text("\n}\n\n"));
      }
    }

    # not within a selector. can be user input or from other methods
    elsif ([~] @$css-bodies) !~~ m/^ \s* $/ {

      $!style.append(.clone-node) for @$css-bodies;
      $css-bodies = [];
    }
  }
}
