# Todo list for the SemiXML module and sxml2xml program

* Parser and actions.
  * [x] Rethinking the parser grammar.
  * [x] Xml Namespaces
  * [x] Doctype entities
  * [x] '#' commenting should be improved using grammar instead of overall removal. Illegal to use comments within [! !]
  * [x] Better error messages when parser fails. But can still be improved.
  * [x] Add another set of brackets which will not allow child elements. This is handy to write javascript and or stylesheets whithout the need to escape every other character like the $ and #.
  * [x] Exporting generated xml to other programs instead of file using config option ```output/program/<run-code>: <command line to run>;```. E.g. when ```output/program/chk: | xmllint --format -;``` is defined in the toml cnfig one can run ```sxml2xml -run chk my-file.sxml```. To get the user information, method save() has a new named argument :$run-code which is the key as in /output/program/<run-code>.
  * [x] Define rules to define spacing around tags. Default would be to have no space at all.
    * [x] ```$|x [ ... ]```. Normal tag where all leading and trailing spaces are removed and between words, spaces are reduced to one space.
    * [x] ```$|x [! ... !]```. Body can not have tags. '$' is ignored and this character as well as ']' do not have to be escaped.
    * [x] ```[ ... ]``` and ```[! ... !]``` can have a '=' directly after the '[' or '[!'. It means that all text must
    be kept as typed. Leading newlines (on the whole text) and trailing spaces (on every line) are still removed.
    * [x] Tags '$\*\*', '$|\*' and '$\*|>' is introduced to add a space to the right or left of the tag and its content.

* Grammar extensions;

* Items needed in program sxml2xml
  * [x] Generate a http header!
  * [x] File extension is .sxml, not yet defined at IANA mimetypes. However, the sxml2xml program will not bother (yet).
  * [x] Dependencies on other files
  * [ ] Partial parsing of prelude or document.
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
