# Todo list for the SxmlLib module tree

* External modules located in SxmlLib tree
  * [x] A methods tag content between [ ... ] is a named argument to the sub called :$content-body having type XML::Element.
  * [x] Library paths to find modules are provided
  * [x] Are introduced via toml config file
  * [x] ```$.tagname <attrs> [<body>]``` for tag name substitution and attribute additions.
  * [x] ```$!tagname <attrs> [<body>]``` for insertion of tags and body using attributes as arguments to subs/methods.
  * [ ] A module should be accessable from within another perl6 sxml module. Problem of registration.
  * [x] Get information from SemiXML e.g. current processed filename.
  * [x] Perl test reports using prove

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
  * [x] File extension is .sxml, not yet defined at IANA mimetypes. However, the sxml2xml program will not bother (yet).
  * [x] Dependencies on other files
  * [ ] Store internal representation back into sxml. This cannot be dynamic for the moment.

* [x] Simplify syntax by removing the prelude and move the options into a config file using TOML. Using module Config::DataLang::Refine searching for options files is as follows;
  * First read program resource version of SemiXML.toml
  * Then merge ~/.SemiXML.toml, ./.SemiXML.toml, ./SemiXML.toml
  * Then using main file.sxml merge; <file-location>/file.toml, ~/.file.toml, ./.file.toml and ./file.toml

  * The top level tables in this configuration result are as follows;

    ```
    [ dependencies ]
    [ module ]
    [ option ]
    [ option.doctype ]
    [ option.xml-prelude ]
    [ option.http-header ]
    [ output ]
    ```

  * These tables are used as the defaults. Then for each file processed, these are prefixed with the filename. E.g. assuming file.sxml;

    ```
    [ dependencies.file ]
    [ option.xml-prelude.file ]
    ```

  * Then for any used module the same kind of table extension but only in the [module] table. E.g. assume module *SxmlLib::Docbook5::Basic* nicknamed *Db5b*;

    ```
    [ module ]

    [ module.Db5b ]
      name    = 'SxmlLib::Docbook5::Basic'
    ```
* [ ] Use Config::DataLang::Refine to select the data according to plan shown above.

* [ ] Use role Pluggable to handle plugin modules. Delivered modules in the Sxml namespace can be handled this way.
* [ ] Use the resources field from META.info to save the core Sxml pluggable modules.

* And ...
  * Documentation.
    * Module and program documentation
    * [ ] Documentation is started as a docbook 5 document. There are references
          to local iconfiles and fonts for which I don't know yet if it may be
          included (license issues).
    * [ ] Tutorials.
