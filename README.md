# SemiXML

[![Build Status](https://travis-ci.org/MARTIMM/Semi-xml.svg?branch=master)](https://travis-ci.org/MARTIMM/Semi-xml)
[![License](http://martimm.github.io/label/License-label.svg)](http://www.perlfoundation.org/artistic_license_2_0)

## Description

Package to generate XML typed languages from an easier readable and writable description plus, because it is written in Perl 6, the possibility to insert XML using code elements.

## Introduction

The following piece of xml (html) text
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
$|html [
  $|head [
    $|title [ Title of page ]
  ]
  $|body [
    $|h1 [ Introduction ]
    $|p class=green [ Piece of text. See $*|a href=google.com [google].]
  ]
]
```
(9 lines, 29 words, 170 characters. Less characters typed and still indenting. Note that characters like ']' is counted as a word!). Besides this the xml generated from the sxml file is smaller than above because it removes as much white space as necessary.

### Advantages of using this language

While the example above does not show a big advantage, however there are some summarized below.

* This semi xml has a bit better reading capabilities because no textual endtag is needed. It is just a closing bracket.
* Attribute values do not need quoting when there are no spaces in the value. However there are three possible quoting characters: ', " and ^.
* An XML element is introduced by **$|** to support simple parsing. This translates just to the XML element. E.g. **$|html []** becomes **< html/>**.
* Other symbols following the **$** changes its meaning.
  * **$!** is used to call a method from an external module to insert xml controlled by data from elsewhere.
  * **$\*\***, **$\*|** and **$|\*** provides for spacing around the tag and its body.

## Ideas and Todo

Please check out the file doc/TODO.md

## Bugs

Check file doc/BUGS.md

## Release notes

For changes look for the file doc/CHANGES.md in this repository.

## Versions of perl using moar vm

* Perl6 version v6.c

## Install

Use panda or zef to install SemiXML

## Aurhor

Marcel Timmerman
