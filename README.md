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

* Parser and actions.
  * [x] Parser is class. Styles can be templated and added in the form of a role.
        The same information can be supplied in the prelude of the source. For all
        settings, defaults are provided when possible.
  * [ ] Xml Namespaces
  * [ ] Doctype entities
  * [ ] '#' commenting should be improved using grammar instead of overall removal
  * [ ] Better error messages when parser fails.
  * [x] Add another set of brackets which will not allow child elements. This
        is handy to write javascript and or stylesheets whithout the need to
        escape every other character like the $ and #.
  * [x] Exporting generated xml to other programs instead of file using prelude
        path ```output/program/<label>: <command line to run>;```. E.g. when
        ```output/program/chk: | xmllint --format -;``` is defined in the
        prelude one can run ```sxml2xml -run chk my-file.sxml```.

        To get the user information save() has a new named argument :$run-code
        which is the key as in /output/program/<run-code>
  * Define rules to define spacing around tags. Default would be to have no
    space at all. This can mean that the current syntax of $x[ ], $x[= ],
    $x[- ] and $x[+ ] may change because it won't be nessesary if layout
    can be defined beforehand.

    Well, that happened;
    * [x] ```$x [ ... ]```. Normal tag where all leading and trailing spaces are
          removed and inbetween spaces reduced to one space.
    * [x] ```$x [! ... !]```. Body can not have tags. '$' is ignored and this
          character as well as ']' do not have to be escaped. Only '#' must
          be escaped at this moment.
    * [x] [ ... ] and [! ... !] can have a '=' directly after the '[' or '[!'.
          Leading newlines and trailing spaces are removed. Furthermore all
          indents are reduced to the minimum spacing as is done in perl6.
    * [x] A tag can start with '$', '$.', '$!'. Now also '$*' is introduced
          which will add a space around the tag and its content.
    * [x] Another addition '$*<' and '$*> is introduced to add a space to the
          left or right of the tag and its content.

* External modules
  * [x] A methods tag content between [ ... ] can be a named argument to the sub.
  * [x] Need library paths to find modules
  * [x] Introduced via source prelude
  * [ ] Introduced via role
  * [ ] Introduced via defaults
  * [x] ```$.tagname <attrs> [<body>]``` for tag name substitution and
        attribute additions.
  * [x] ```$!tagname <attrs> [<body>]``` for insertion of tags and body using
        attributes as arguments to subs/methods.

* Now modules can be used from sxml, the following libs might come in handy
  * SxmlLib::File - File and link handling.
    * [x] include() other documents.
    * [ ] link to page or image checking and generating.
  * SxmlLib::Html::List - Html lists like ul/li
    * [x] dir-list() to recursively create list of files and directories.
  * SxmlLib::Docbook5::Basic - Basic docbook methods
    * [x] book and article substitute tags to add extra attributes to the tag.
    * [x] info() to specify the elaborate info tag in an easy way.

  * And ...
    * [ ] avatar linking
    * [ ] Generating tables
    * [ ] generating graphics, statistics, svg etc
    * [ ] Lorem ipsum generator.

  * A Sxml core library included by default to handle simple items like
    * [x] comment() for comments <!-- ... -->.
    * [x] PI() for <?...?>.
    * [x] CData() for <[CDATA[...]]>.
    * [x] date() for date
    * [x] date-time() for datetime.

* Items needed in program sxml2xml
  * [x] Generate a http header!
  * [x] File extension is .sxml, not yet defined at IANA mimetypes. However, the
        sxml2xml program will not bother (yet).
  * [x] Dependencies on other files
  * [ ] Partial parsing of prelude or document.

* And ...
  * Documentation.
    * Module and program documentation
      * [ ] Semi-xml
      * [ ] Semi-xml::Action
      * [ ] Semi-xml::Grammar
      * [ ] Semi-xml::SxmlCore
      * [ ] Semi-xml::Text
      * [ ] sxml2xml
    * [ ] Is now started as a docbook 5 document. There are references to local
          iconfiles and fonts for which I don't know yet if it may be included.
    * [ ] Tutorials.

## Bugs

Still at omega state, bugs come and go(hopefully).
* If dir and file is ```X/abc.sxml``` and there is a prelude used with
  ```output/filename: index;```, then running the file the result file come at
  the right spot. Depending on the default, the result will come in dir X. Using
  ```output/filename: ../index;``` the result will come in the directory below
  the users directory. Need to think about this what is best. Maybe add a config
  item, something like filepath.
* At the moment it is too complex to handle removal of a minimal indentation in
  in pieces of text which must be kept as is typed. Needed in e.g. <pre> in html
  or <programlisting> in docbook. The complexity is caused by using child
  elements in such tags.

## Changes

* 0.15.0
  * Output of http header
* 0.14.4
  * Change way comments are processed. Needs some extra work.
* 0.14.3
  * File.pm6 had a bug which didn't include the files anymore. Unknown how
    and why it was intrduced.
  * Bugfix of spacing around tags. One too many modifications of XML::Text into
    Semi-xml::Text.
* 0.14.2
  * Added a trick from the panda program to reorder the options to the front so
    the sxml files can be made executable and on the commandline some added
    options which would come after the filename instead of before.
* 0.14.1
  * Bugfix. spacing around text. XML::Text completely replaced by Semi-xml::Text
* 0.14.0 Introducing $*<tag and $*>tag to add a space to the left or right.
* 0.13.2
  * Bugfix serializing < and > into &lt; and &gt;.
  * Bugfix using docbook <co> in <programlisting>. Needed some changes in
    the grammar in capturing spaces around elements.
* 0.13.1
  * Bugfix spacing around tag by modifying Semi-xml::Text.
* 0.13.0 Added Docbook5 basic module SxmlLib::Docbook5::Basic.
* 0.12.0 Change of syntax to better control spacing and layout.
* 0.11.0
  * Feed xml result to other programs. Not directly but with a work around.
  * Preparations to use xml namespaces.
  * Start of documentation in the doc directory using the semi-xml language.
* 0.10.0
  * Added methods for xml comment, cdata and pi.
* 0.9.5
  * Bugfix in dependencies due to inititializing step
  * Initialization of Semi-xml and Actions class.
  * Complex nesting of body contents now possible with $!mod.meth [ ]. Also
    another call to a method is possible in the content body, The content is
    saved in an element named 'PLACEHOLDER-ELEMENT'. This element is given to
    the method where the method does anything with it. The method must remove the
    element after processing.
* 0.9.4
  * Bugfix of introduced spacing caused by empty strings.
  * Bugfix finding options after parsing with multi method get-option()
* 0.9.3
  * When using [= or [+ the modules will try to reduce the white space in the
    same way as perl 6 does with q:to//.
  * The filepath is introdused in the prelude. The default will be '.'
  * The dependencies is introdused in the prelude. The library will not use
    it and no default is an empty string. A program using the libraries will
    need to use it and the sxml sources must define it.
* 0.9.2
  * $!file.dir-list ref-attr=data_href
    Option to set another attrbute for the reference instead of the default href.
* 0.9.1
  * $!file.dir-list header=1,2,3
    Attribute header can be a list of numbers meaning h1,h2,h3 in this case. Max
    is for 6 levels and missing levels become the same as the last level.
  * $!file.dir-list, extra attributes copied to top level <ul>.
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


