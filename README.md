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

While the example above does not show a big advantage, there are some summarized below.

* This semi xml has a bit better reading capabilities because no textual end tag is needed. It is just a closing bracket.
* Attribute values do not need quoting when there are no spaces in the value. However there are three possible quoting characters: ', " and ^.
* An XML element is introduced by **$|**. This translates just to the XML element. E.g. **$|html []** becomes **<html/>**.
* Empty element content does not have to be written in the way shown above. It can be written just like **$|html**.
* Other symbols following the **$** changes its meaning.
  * **$!** is used to call a method defined in an external module to insert xml controlled by data from elsewhere. This is the most important part of this package because with a simple sxml line a table can be created with data from a database. More humble things can also be accomplished e.g. generating the start of a document with lots of namespace declarations or inserting the current date and time.
  * **$\*\***, **$\*|** and **$|\*** provides for spacing around the tag and its body when these are used as inline elements like 'a', 'b', 'strong' etc.
* Square brackets **[** and **]** are used to contain nested text or other element nodes as shown in the example above. Adding a few character on the brackets changes the use also.
  * **[!** and **!]** are used where no nested node elements are allowed. This comes in handy when text is entered with a lot of **$** characters like javascript or perl.
  * **[=** **]** (Note '=' only on the opening bracket). This means that the content needs to be kept as it is written. Important when showing code or something like that.
  * **[!=** and **!]** which is a combination of the two i.e. keep text as is and do not interprete element nodes.
  * When an element needs sections where some element nodes are needed and other sections where it easier to turn it off one can write several of those after each other like for example; **$|p [! The following line; my $p = 10 \* $a; !] [ assigns 10 times the value of $\*\*b[! $a !] to the variable $\*\*b[! $p !]. ]**.

## Documentation
Documentation is not sufficiently available to help the user out. There is a manual in the making but there is also a need of documentation about the classes and program of this package.

### SemiXML
This is about the SemiXML::Sxml class and sxml2xml program.

* [Release notes](https://github.com/MARTIMM/Semi-xml/blob/master/doc/SemiXML/CHANGES.md)
* [Bugs and Todo](https://github.com/MARTIMM/Semi-xml/blob/master/doc/SemiXML/TODO.md)

### SxmlLib
This is about the defined methods in external modules. Some examples already available are space fillers like Lorem Ipsum' text, inserting PI, COMMENT or CDATA, inserting date and time, generating some doctype elements etcetera.

* [Release notes](https://github.com/MARTIMM/Semi-xml/blob/master/doc/SxmlLib/CHANGES.md)
* [Bugs and Todo](https://github.com/MARTIMM/Semi-xml/blob/master/doc/SxmlLib/TODO.md)

## Versions of perl using moar vm

* Perl6 version v6.c

## Install

Use zef to install SemiXML

## Author

Marcel Timmerman
