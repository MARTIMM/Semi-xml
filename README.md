# Semi-xml

## Description

Package to generate xml from an easier readable and writable description plus,
because it is written in perl 6, the possibility to insert xml from other
sources such as files, text, code , variables etc.

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
(9 lines, 29 words, 161 characters. Less characters typed and still indenting.)

This second form looks much more airy and better to read. There are also some
other advantages using it this way. It will be even better to read when language
highlights are programmed in your favorite editor.

* You don't need to write the endtag.
* Nesting is easy using the brackets.
* Attribute values do not need quoting when there are no spaces in the value.
* By using the $ as a start of the tag it can also be interpreted as 
  being a scalar variable and handled as such replacing the tagname with some
  other text depending on the type of that variable.
  When it exists it can do something with it depending on the type.
  * Undefined: Remove the $, e.g.```$html -> html```
  * Str: Substitute the strings value., e.g. if ```my Str $xtbl = 'table';```
    then ```$xtbl -> table```.
  * Callable: Call a method/sub to return data to be placed on that spot.
    The attributes will become the arguments to the function. The function must
    return a name for the tag and new attributes if any.
* The parser calls methods from the action object to handle all tags and
  attributes. Hooks can be inserted to handle special items e.g.
  * Html needs stylesheets in another format than xml. These can be introduced
    by using a hash.
  * Some html tags need other processing than the default handling and must
    be configured before parsing. E.g.
    * script tags must always have a start and end tag
    * the content of a pre tag must be left as-is.

## Ideas and Todo

* [x] Parser is class. Styles can be templated and added in the form of a role.
      The same information can be supplied in the prelude of the source. Of all
      settings, defaults are provided when possible.
* [x] File extension is .sxml, not yet defined at IANA mimetypes. However, the
      sxml2xml program will not bother (yet).
* [ ] Generate a content header!
* [ ] Xml Namespaces
* [ ] Comments <!-- ... --> Not needed!
* [ ] Processing Instructions <?PI ...?>
* [ ] Cdata <[CDATA[...]]>
* External modules
  * [x] Need library paths to find modules
  * [x] Introduced via source prelude
  * [ ] Introdused via role
  * [x] tag name substitution and attribute additions. Format is ```$.tagname
        <attrs> [<body>]```.
  * [x] insertion of tags and body using attributes as arguments to
        subs/methods. Format ```$!tagname <attrs> [<body>]```
* [ ] Documentation.
* [ ] Tutorials.
* [ ] Better error messages when parser fails.
* Now modules can be inserted, the following might come in handy
  * [ ] File and link handling.
    * [ ] include other documents
    * [ ] link to page or image checking and generating
    * [ ] avatar linking
  * [ ] Generating tables
  * [ ] generating graphics, statistics, svg etc

## Bugs

Still at omega state, bugs come and go(hopefully).

## Changes

* 0.7.0
  * Tagnames: $.name = substitute name and add attributes, $!name call function

* 0.6.1
  * Trying out several formats for tags. $tag and ..tag. Then use $html for some
    other purpose like substitution etc. and ..tag for normal cases. It happens
    that the '..' is not the best choice.
  * Bugfix: tags with body |[ ...]| were not saved.
* 0.6.0 Added tagname substitution and addition of attributes from external
        modules.
* 0.5.1
  * ```$tag attr=val |[ content ]|``` doesn't work properly because the text
    from the XML comes back wrong. Serializing all by my self is not (yet)
    desirable. This is now fixed by creating a class with the 'proper' method in
    it.
    ```
    class Semi-xml::Text is XML::Text {
      method Str {
        return $.text;
      }
    }
    ```
    And later use the new class like so
    ```
    my $xml = Semi-xml::Text.new(:text($esc-text));
    $element-stack[$current-element-idx].append($xml);
    ```
    Later when the text is requested it will use the Str() method from the new
    class and I am happy.

* 0.5.0
  * Program to convert sxml to xml.
  * Prelude grammar and actions
    * Unix startup #! on first line possible
    * Control info with the document. Then it is possible to generate xml by
      running the document. Then it is also possible to have the document be used
      like a serverside script. Must generate a content header!
  * Use of defaults from internal structure if config from user role or from
    file prelude is not available.
*.0.4.1 * Bugfix attribute handling
* 0.4.0
  * Parse file
  * Add prefix:<~>
  * Add comments and escape
  * Semi-xml now does Semi-xml::Actions. Brings data closer to Core class.
  * Optionally generate xml prelude and/or doctype
* 0.3.1 Handle escape characters
* 0.3.0 Generate XML
* 0.2.0 Grammar installed
* 0.1.0 Start thinking. Always do that before doing.

## Aurhor

Marcel.Timmerman

## License

Released under [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).


