# SemiXML

[![Build Status](https://travis-ci.org/MARTIMM/Semi-xml.svg?branch=master)](https://travis-ci.org/MARTIMM/Semi-xml) [![License](http://martimm.github.io/label/License-label.svg)](http://www.perlfoundation.org/artistic_license_2_0)

## Description

Package to generate XML typed languages from an easier readable and writable description plus, because it is written in Perl 6, the possibility to insert new elements using methods in external objects.

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
    <p>The date of today is 2015-03-01</p>
  </body>
</html>
```

can be written in this semi xml language as

```
$html [
  $head [
    $title [ Title of page ]
  ]
  $body [
    $h1 [ Introduction ]
    $p class=green [ Piece of text. See $a href=google.com [google].]
    $p [ The date of today is $!SxmlCore.date ]
  ]
]
```
Less characters typed and still indenting. Besides this, the xml generated from the sxml file is smaller than above because it removes as much white space as possible. Also note the date in the html example is hand-crafted while in the sxml example the current date is generated on each run.

### Advantages of using this language

While the example above does not show a big advantage, there are some summarized below.

* This semi xml has a bit better reading capabilities because no textual end tag is needed. It is just a matching closing bracket. (**]**, **}** or **»**).
* Attribute values do not need quoting when there are no spaces in the value. However there are three possible quoting characters: **'**, **"** and **\< \>** when needed.
* An XML element is introduced by **\$**. This translates just to the XML element. E.g. **\$abc []** becomes **\<abc/>** or **\<abc>\</abc>** depending on some other information found in the configuration.
* Empty element content does not have to be written in the way shown above. It can be written just like **\$abc**. However, when attributes are used, the brackets are needed. This is made obligatory to make the text following an empty content better visually separated from the element and also to have better checks when mistakes are made.
* Other symbols following the **\$** changes its meaning. For the moment there is only one change namely;
  * **\$!**. This symbol is used to call a method defined in an external module. This method normally will insert xml elements. This process is controlled by e.g. attributes, its content or by data found elsewhere. This is the most important purpose of the package because with a simple sxml method a table can be created with data from a database. More humble things can also be accomplished e.g. generating the start of a document with lots of namespace declarations or inserting the current date and time.
* Square brackets **[** and **]** are used to contain nested text or other element nodes as shown in the example above. There are other characters which can be used instead;
  * **{** and **}** are used where no nested node elements are allowed. This comes in handy when text is entered with a lot of **\$** characters like in javascript or perl code. Comments are not filtered out in these texts.
  * **«** **»**. These brackets have the same meaning as above but there is less need to escape characters.
  * When an element needs sections where some element nodes are needed and other sections where it easier to turn it off one can write several of those after each other like for example; **\$p { The following line; my \$p = 10 \* \$a; }[ assigns 10 times the value of \$b{ \$a } to the variable \$b« \$p ». ]**.

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

* Perl6 version v6

## Install

Use zef to install SemiXML

## Author

Marcel Timmerman
