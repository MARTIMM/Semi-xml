use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::StringList;
use SemiXML::Text;
use SxmlLib::SxmlHelper;
use XML;

#-------------------------------------------------------------------------------
# Core module with common used methods
class Css {

  #-----------------------------------------------------------------------------
  method style (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    # put everything into a style variable to prevent any escape substitutions
#`{{
    my XML::Element $var = append-element(
      $parent, 'sxml:variable', {name => 'style'}
    );
    my XML::Element $style = append-element( $var, 'style', :text("\n"));
    append-element( $parent, 'sxml:style');
}}

    # because of this a style can be placed anywhere in the document and then
    # it will be remapped to the end of the head.
    my XML::Element $remap-style = append-element(
      $parent, 'sxml:remap', { map-to => "/html/head",}
    );

    my XML::Element $style = append-element(
      $remap-style, 'style', :text("\n")
    );

    drop-parent-container($content-body);
#note "\nContent0 $content-body";
    subst-variables($content-body);
#note "\nContent1 $content-body";

    self!css-blocks( $style, $content-body, '', ? ($attrs<compress>//0).Int);

#note "Result css\n", '-' x 80, "\n$style\n", '-' x 80;

    $parent
  }

  #-----------------------------------------------------------------------------
  #https://perishablepress.com/a-killer-collection-of-global-css-reset-styles/
  method reset (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {
    my Str $type = ($attrs<type>//'minimalistic').Str;
    given $type {
      when 'minimalistic' {
        append-element( $parent, :text(q:to/EOCSS/));
            * {
            	outline: 0;
            	padding: 0;
            	margin: 0;
            	border: 0;
          	}
            EOCSS
      }

      when 'condensed-universal' {
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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
        append-element( $parent, :text(q:to/EOCSS/));
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

#`{{
      when '' {
        append-element( $parent, :text(q:to/EOCSS/));

            EOCSS
      }
}}
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  method b (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my Str $selector = ~($attrs<s>//'*');
    my XML::Element $css-block = append-element(
      $parent, 'sxml:css-block', {s => $selector}, :text("\n")
    );
    $css-block.append($content-body);
    append-element( $css-block, :text("\n\n"));

    $parent
  }

  #-----------------------------------------------------------------------------
  #---[ private ]---------------------------------------------------------------
  method !css-blocks (
    XML::Element $style, XML::Element $css-block, Str $parent-select,
    Bool $compress
  ) {

    my Bool $is-block =
            (($css-block ~~ XML::Element) and ($css-block.attribs<s>:exists));
    my Str $css-body = '';

    # build current selector
    my Str $select = '';

    if $is-block {
      $select = [~] $parent-select,
                    (?$parent-select ?? ' ' !! ''),
                    $css-block.attribs<s>;
    }

    # do the textual parts first, then process rest
    for $css-block.nodes -> $node {
      if $node ~~ any(XML::Text, SemiXML::Text) {
        $css-body ~= $node.Str;
      }
    }

    # if the css body is not a string of only spaces, add it to the style
    if $is-block and $css-body !~~ m/^ \s* $/ {
#note "Body: $css-body";

      $css-body ~~ s:g/ \s\s+ / /;
      $css-body ~~ s:g/ \n / /;
      if $compress {
        $css-body = "$select \{$css-body}\n";
      }

      else {
        $css-body ~~ s:g/ \s* ';' (\S*) /;\n$0  /;
        $css-body ~~ s:g/ \s+ $//;
        $css-body = "$select \{\n  $css-body\n}\n\n";
      }

      $style.append(SemiXML::Text.new(:text($css-body)));
    }

    # not within a selector. can be user input or from other methods
    elsif $css-body !~~ m/^ \s* $/ {
#note "CB 0: $css-body";
      $css-body ~~ s:g/ \s\s+ / /;
      $css-body ~~ s:g/ \n / /;
      $css-body ~~ s:g/ \s+ '}' /}/;
      if !$compress {
        $css-body ~~ s:g/ \s* ';' (\S*) /;\n$0  /;
        $css-body ~~ s:g/ \s+ $//;
      }

      $css-body = "$css-body\n";
      $style.append(SemiXML::Text.new(:text($css-body)));
    }



    # process the rest of the blocks
    for $css-block.nodes -> $node {
      if $node ~~ XML::Element and $node.name eq 'sxml:css-block' {
        self!css-blocks( $style, $node, $select, $compress);
      }
    }
  }
}
