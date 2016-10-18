# Semi-xml

[![Build Status](https://travis-ci.org/MARTIMM/Semi-xml.svg?branch=master)](https://travis-ci.org/MARTIMM/Semi-xml)
[![License](https://raw.githubusercontent.com/MARTIMM/Semi-xml/develop/label/License-label.svg)](http://www.perlfoundation.org/artistic_license_2_0)

## Description

Package to generate xml from an easier readable and writable description plus,
because it is written in perl 6, the possibility to insert xml from other
sources such as files, text, code , variables etc.

## Introduction

I'm a lazy bum, so writing xml is too exhausting. instead of writing;

```
<html>
  <head>
    <title> Title of page </title>
  </head>
  <body>
    <h1> Introduction </h1>
    <p class='green'> Piece of text. See <a href='google.com'>google</a>. </p>
  </body>
</html>
```
(9 lines, 23 words, 195 characters)

I want to do something like the following

```
$html [
  $head [
    $title [ Title of page ]
  ]
  $body [
    $h1 [ Introduction ]
    $p class=green [ Piece of text. See $*<a href=google.com [google].]
  ]
]
```
(9 lines, 29 words, 164 characters. Less characters typed and still indenting. Note that characters like ']' is counted as a word!).

This second form looks much more airy and better to read. There are also some other advantages using it this way. It will be even better to read when language highlights are programmed in your favorite editor.

### Advantages of using this language

* As mentoned above it has better reading capabilities.
* You don't need to write the xml endtags because of nesting.
* Attribute values do not need quoting when there are no spaces in the value.
* A tag is introduced by the '$' to support simple parsing. This translates just to the XML tagname. E.g. $html [] becomes <html></html>.
* Additional symbols following the '$' changes its intent.
  * '$.' to provide simple substitution and adding extra attributes.
  * '$!' is used to call a method from an external module to insert new or change existing content. When the rules for substitution or the methods are not found then the tag will be as if no '.' or '!' is used.
  * '$\*', '$\*<' and '$\*>' provides for spacing around the tag and its body.

## Ideas and Todo

Please check out the file doc/TODO.md

## Bugs

Still at omega state, bugs come and go(hopefully).
* If dir and file is ```X/abc.sxml``` and there is a prelude used with ```output/filename: index;```, then running the file the result file come at the right spot. Depending on the default, the result will come in dir X. Using ```output/filename: ../index;``` the result will come in the directory below the users directory. Need to think about this what is best. Maybe add a config item, something like filepath.
* At the moment it is too complex to handle removal of a minimal indentation in in pieces of text which must be kept as is typed. Needed in e.g. tags pre in html or programlisting in docbook. The complexity is caused by using child elements in such tags.
* All indents of generated documents should unindented to proper level are reduced to the minimum spacing as is done in perl6.

## Changes

For changes look for the file doc/CHANGES.md in this repository.

## Aurhor

Marcel Timmerman
