# Semi-xml

## Description

Package to generate xml from an easier readable and writable description plus,
because it is written in perl 6, the possibility to insert xml from other source
such as files, text, code , variables etc.

## Introduction

I'm a lazy bum, so writing xml is too exhousting. instead of writing;

```xml
<html>
  <head>
    <title> Title of page </title>
  </head>
  <body>
    <h1> Introduction </h1>
    <p class='green'> Piece of text. See <a href='google.com'>google</a> </p>
  </body>
</html>
```
(9 lines, 23 words, 194 characters)

I want to do something like the following

```
$html [
  $head [
    $title [ Title of page ]
  ]
  $body [
    $h1 [ Introduction ]
    $p class=green [ Piece of text. See $a href=google.com [google]]
  ]
]
```
(9 lines, 29 words, 161 characters)

This second form looks much more airy and better to read. There are also some
other advantages using it this way.

* You don't need to write the endtag. Less characters typed and still indenting.
* By using the $ on the tag name the parser code can try to lookup a scalar
  variable. When it exists it can do something with it depending on the type.
  * Str - Substitute the strings value
  * Callable - Call a method/sub to return data to be placed on that spot.
* Nesting is easy using the brackets.
* Attribute values do not need quoting when there are no spaces in the value.
* The parser calls methods from the action object to handle all tags and
  attributes. Hooks can be inserted to handle special items e.g.
  * Html needs stylesheets in another format than xml. These can be introduced
    by using a hash.
  * Some html tags need other processing than the default handling and must
    be configured before parsing. E.g.
    * script tags must always have a start and ending tag
    * the content of a pre tag must be left as-is.


