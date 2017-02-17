# Bugs and Todo list for the SemiXML modules and sxml2xml program

* Parser and actions.
  * Error messages when parser fails can still be improved.

* Grammar extensions;
  * Remove '=' directly after '[' to keep text as it is typed. This is often forgotten by me, so others may have the same problem. Also it makes the grammar cleaner. Instead the following can be done to have the same effects;
    * No changes at all when the body content is given to a method.
    * Specific tag can be defined in the config. Most common in html is *script*, *style* and *pre* of which the first two are not really necessary.

* External modules located in SxmlLib tree
  * Library paths to find modules are provided
  * A module should be accessable from within another perl6 sxml module. Problem of registration.
  * Use a plugin system for the modules.
  * Store SxmlLib modules in the resources directory.

* Items needed in program sxml2xml or SemiXML.pm6
  * Dependencies on other files
  * Store internal representation back into sxml.
  * Load any xml based source to convert back to sxml. Can be used as a start for templating things using pages from a nice website.

* Tests
  * tags without body but with attributes
  * comments in sxml
  * lineup of brackets of body to find errors

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
  * These tables are used as the defaults. Then for each file processed, these are postfixed with the filename without extention. E.g. assuming file.sxml;

    ```
    [ dependencies.file ]
    [ option.xml-prelude.file ]
    ```

  * Another option is to use the formats the sxml file is supposed to represent and the format it has to become. These should be set using the options to the sxml2xml program. E.g **'--in=html --out=html'** or **'--in=docbook5 --out=pdf'**. This way the configuration can describe what should be done with, for example, the xml prelude, the doctype declaration or which command to select to get the result.

    ```
    # --out=html
    [ option.xml-prelude.html ]
    [ output.program.html ]

    # --in=docbook5
    [ module.docbook5 ]
    ```

  * or both combined where file comes first
    ```
    # file is xyz.sxml, --in=docbook, --out=chunked-html
    [ output.program.xyz.chunked-html ]
    ```
  All these ideas could also replace the one option --run which only had a selective influence on the output.program table.

* Use Config::DataLang::Refine to select the data according to plan shown above.

* Use role Pluggable to handle plugin modules. Delivered modules in the Sxml namespace can be handled this way.
* Use the resources field from META.info to save the core Sxml pluggable modules.

* And ...
  * Documentation.
  * Module and program documentation
  * Documentation is started as a docbook 5 document. There are references to local iconfiles and fonts for which I don't know yet if they may be included (license issues).
  * Tutorials.
