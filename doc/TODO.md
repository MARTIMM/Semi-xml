
* Parser and actions.
  * [x] Parser is a class. Styles can be templated and added in the form of a role. The same information can be supplied in the prelude of the source. For all settings, defaults are provided when possible.
  * [ ] Xml Namespaces
  * [ ] Doctype entities
  * [ ] '#' commenting should be improved using grammar instead of overall removal
  * [ ] Better error messages when parser fails.
  * [x] Add another set of brackets which will not allow child elements. This is handy to write javascript and or stylesheets whithout the need to escape every other character like the $ and #.
  * [x] Exporting generated xml to other programs instead of file using prelude path ```output/program/<label>: <command line to run>;```. E.g. when ```output/program/chk: | xmllint --format -;``` is defined in the prelude one can run ```sxml2xml -run chk my-file.sxml```. To get the user information save() has a new named argument :$run-code which is the key as in /output/program/<run-code>
  * [ ] Define rules to define spacing around tags. Default would be to have no space at all.
    * [x] ```$x [ ... ]```. Normal tag where all leading and trailing spaces are removed and inbetween spaces reduced to one space.
    * [x] ```$x [! ... !]```. Body can not have tags. '$' is ignored and this character as well as ']' do not have to be escaped. Only '#' must be escaped at this moment.
    * [x] ```[ ... ]``` and ```[! ... !]``` can have a '=' directly after the '[' or '[!'. Leading newlines and trailing spaces are removed.
    * [x] A tag can start with '$', '$.', '$!'. Now also '$\*' is introduced which will add a space around the tag and its content.
    * [x] Another addition '$\*<' and '$\*>' is introduced to add a space to the left or right of the tag and its content.

* External modules
  * [x] A methods tag content between [ ... ] is a named argument to the sub called content-body.
  * [x] Library paths to find modules are provided
  * [x] Can be introduced via source prelude
  * [ ] Can be introduced via role
  * [ ] Can be introduced via defaults
  * [x] ```$.tagname <attrs> [<body>]``` for tag name substitution and attribute additions.
  * [x] ```$!tagname <attrs> [<body>]``` for insertion of tags and body using attributes as arguments to subs/methods.

* Now modules can be used from sxml, the following libs might come in handy
  * SxmlLib::File - File and link handling.
    * [x] include() other documents.
    * [ ] link to page or image checking and generating.
  * SxmlLib::Html::List - Html lists like ul/li
    * [x] dir-list() to recursively create list of files and directories.
  * SxmlLib::Html::FixedLayout - Content from files to be used in pre elements.
    * [x] load-test-example
  * SxmlLib::Docbook5::Basic - Basic docbook methods
    * [x] book and article substitute tags to add extra attributes to the tag.
    * [x] info() to specify the elaborate info tag in an easy way.

  * And ...
    * [ ] avatar linking
    * [ ] Generating tables
    * [ ] Generating graphics, statistics, svg etc
    * [x] Lorem ipsum generator.

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
  * [ ] Store internal representatio back into sxml. This cannot be dynamic for
        the moment.

* And ...
  * Documentation.
    * Module and program documentation
      * [ ] Semi-xml::Sxml
      * [ ] Semi-xml::Action
      * [ ] Semi-xml::Grammar
      * [ ] Semi-xml::SxmlCore
      * [ ] Semi-xml::Text
      * [ ] sxml2xml
    * [ ] Documentation is started as a docbook 5 document. There are references
          to local iconfiles and fonts for which I don't know yet if it may be
          included.
    * [ ] Tutorials.
