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

* You don't need to write the xml endtags because of nesting.
* Attribute values do not need quoting when there are no spaces in the value.
* A tag is introduced by the '$'. Normally this translates just to the tagname.
  Special handling can be done by adding a character after the '$'. At the
  moment these are a '.' to provide simple substitution and adding extra
  attributes. The character '!' is used to call a method from an external module
  to insert new content or change it. When the rules for substitution or the
  methods are not found then the tag will be as if no '.' or '!' is used.

## Ideas and Todo

* [x] Parser is class. Styles can be templated and added in the form of a role.
      The same information can be supplied in the prelude of the source. Of all
      settings, defaults are provided when possible.
* [ ] Xml Namespaces
* [ ] '#' commenting should be improved using grammar instead of overall removal
* [ ] Dependencies on other files
* External modules
  * [x] Need library paths to find modules
  * [x] Introduced via source prelude
  * [ ] Introdused via role
  * [ ] Introdused via defaults
  * [x] tag name substitution and attribute additions. Format is ```$.tagname
        <attrs> [<body>]```.
  * [x] insertion of tags and body using attributes as arguments to
        subs/methods. Format ```$!tagname <attrs> [<body>]```
* [ ] Documentation.
* [ ] Tutorials.
* [ ] Better error messages when parser fails.
* [x] Add another set of brackets which will not allow child elements. This
      is handy to write javascript and or stylesheets whithout the need to
      escape every other character like the $ and #. [-...] perhaps?
* Replacing anonymous methods in an external module from the hash to class
  methods.
* Now modules can be used from sxml, the following libs might come in handy
  * SxmlLib::File - File and link handling.
    * [x] include other documents
    * [ ] link to page or image checking and generating
    * [ ] avatar linking
  * [ ] Generating tables
  * [ ] generating graphics, statistics, svg etc
  * A by default included library to handle special items like
    * [ ] Comments <!-- ... --> Not needed?. Perhaps ```$!Comment []```.
    * [ ] Processing Instructions <?PI ...?>. Perhaps ```$!PI target=php []```.
    * [ ] Cdata <[CDATA[...]]> Perhaps ```$!CData []```.
    * [x] Date and time. ```$!SxmlCore.date []``` and ```$!SxmlCore.date-time```.
* Items needed in program sxml2xml
  * [ ] Exporting generated xml to other programs instead of file
  * [ ] Generate a content header!
  * [x] File extension is .sxml, not yet defined at IANA mimetypes. However, the
        sxml2xml program will not bother (yet).

## Bugs

Still at omega state, bugs come and go(hopefully).
* If dir and file is ```X/abc.sxml``` and there is a prelude used with
  ```output/filename: index;```, then running the file the result file come at
  the right spot. Depending on the default, the result will come in dir X. Using
  ```output/filename: ../index;``` the result will come in the directory below
  the users directory. Need to think about this what is best. Maybe add a config
  item, something like filepath.

## Changes

* 0.9.1
  * $!file.dir-list header=1,2,3
    Attribute header can be a list of numbers meaning h1,h2,h3 in this case. Max
    is for 6 levels and missing levels become the same as the last level.
* 0.9.0
  * Add core sxml core methods, $!SxmlCore.date and $!SxmlCore.date-time
* 0.8.4
  * Done the same for the ```$.tag```. It has become ```$.module.tag```.
  * Bugfix in quoted attributes.
* 0.8.3
  * Again syntax change for using module methods. The ```$!method ...``` is
    extended to be ```$!module.method ...``` when method can be found in a
    module set in the config. E.g.
    ```
    ---
    module/file: SxmlLib::File;
    ---
    $!file.dir-list dir=. []
    ```
* 0.8.2
  * Syntax modifications and additions
    [...]               Normal processing. May have nested tags.
    |[...]| -> [=...]   Keep contant as is written
    [-...]              Only text content and no neted tags.
    [+...]              Same as above but keep cotent as written.

* 0.8,1 * Replacing anonymous methods in an external module from the hash to
          class methods.
* 0.8.0 * Include another doc from sxml with Sxml::Lib::File.
* 0.7.0 * Tagnames: $.name = substitute name and add attributes, $!name call
          function.
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


