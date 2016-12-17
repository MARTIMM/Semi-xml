# Todo list for the SemiXML module and sxml2xml program

* Parser and actions.
  * Error messages when parser fails can still be improved.
  * Check on indenting on '[' and ']'?

* Grammar extensions;
  * Remove '=' directly after '[' to keep text as it is typed. This is often forgotten by me, so others may have the same problem. Also it makes the grammar cleaner. Instead the following can be done to have the same effects;
    * No changes at all when the body content is given to a method.
    * Specific tag can be defined in the config. Most common in html is <script>, <style> and <pre> of which the first two are not really necessary.

* External modules located in SxmlLib tree
  * Library paths to find modules are provided
  * A module should be accessable from within another perl6 sxml module. Problem of registration.

* Items needed in program sxml2xml
  * Dependencies on other files
  * Store internal representation back into sxml.

* Configuration
  * Search for config files (assume parsed file is fpath/file.sxml)
    * Merge <resource-location>/<sha-encoded SemiXML.toml>,  <fpath>/SemiXML.toml, ~/.SemiXML.toml, ./.SemiXML.toml, ./SemiXML.toml, <fpath>/file.toml, ~/.file.toml, ./.file.toml and ./file.toml

  * The top level tables in this configuration result are as follows;

    ```
    [ dependencies ]
    [ module ]
    [ option ]
    [ option.doctype ]
    [ option.xml-prelude ]
    [ option.http-header ]
    [ output ]
    [ output.program ]

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
