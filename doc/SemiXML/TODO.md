# Bugs and Todo list for the SemiXML::* modules and sxml2xml program

* Parser and actions.
  * Error messages when parser fails can still be improved.


* Grammar extensions;
  * Remove '=' directly after '[' to keep text as it is typed. This is often forgotten by me, so others may have the same problem. Also it makes the grammar cleaner. Instead the following can be done to have the same effects;
    * No changes at all when the body content is given to a method.
    * Specific tag can be defined in the config. Most common in html is *script*, *style* and *pre* of which the first two are not really necessary.


* Syntax
  * XML element name can contain any alphanumeric characters. The only punctuation mark allowed in names are the hyphen '-', underscore '\_' and period '.'. Xml namespaces are separated by a colon ':'. These characters can not be used to start an element or to separate a module key from its method.

```
      Current syntax          Becomes             Config    Done

      $|xyz []                $xyz                -         x
      $|xyz [x]               $xyz [x]            -         x

      $*|inline [x]           $inline [x]         x
      $|*inline [x]           $inline [x]         x
      $**inline [x]           $inline [x]         x

      $|nonnest [! x !]       $nonnest [x]        x
      $|spcresrv [= x ]       $spcresrv [x]       x

      Remains the same
      $!key.method [x]

```
  The space reserving '=' and non nesting '!' characters at the start of a block does not have to be removed completely but can just be used ocasionally in case it is needed in a particular situation. E.g. To write css text it is not needed to have a space reserving block of text. However, to check the result, it is better to view it in a readable format.

  The inline elements must also check for some non alphanumeric characters following the block. E.g. in case of ',', '.' etc. no space should be placed between the block and the following character.

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

  * Another option is to use the formats the sxml file is supposed to represent and the format it has to become. When choosing the proper commandline options one must keep the following in mind. First the document written is always **sxml**. What it represents should be the first option (by default **xml**) and what it should become the next option (by default **xml**). These options are provided by the sxml2xml program. The following **--in** and  **--out** with e.g. **--in=docbook5** and  **--out=pdf**. This way the configuration can describe what should be done with, for example, the xml prelude, the doctype declaration or which command to select to get the result. To also use the refine method from Config::DataLang::Refine, the options are used as keys to that method. A third key can be added, the basename of the file being parsed. So the next configuration tables are possible ();

    ```
    # [D] table is used as a general default
    [ D ]
    [ D.in-key ]
    [ D.in-key.out-key ]
    [ D.in-key.out-key.file ]

    # [E] Entity table. Only with out-key and file.
    [ E ]
    [ E.out-key ]
    [ E.out-key.file ]

    # [M] Module table, only with in-key
    [ M ]
    [ M.in-key ]

    # [R] Run table only with in-key and file. The out-key is used to select
    # the command line.
    [ R ]
    [ R.in-key ]
    [ R.in-key.file ]
      out-key   = command line

    ```

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
  All these ideas could also replace the one option --run from the program which only had a selective influence on the [output.program] table. Also less files might be searched through as opposed to the list shown above.

* Use Config::DataLang::Refine to select the data according to plan shown above.
Uhmmmm..., totally wrong! Using refine() it gathers key/values from the config into one set depending on keys used. So here it is use 1) use module only to get the config from one or more files or 2) like one but use also refine() to get a **flat** list of key/values. This means that the key names must be rethought and changed to cope with that. Perhaps a special key name could flip between one or the other. Old configs could still be used with the key turned off. Could even use both setups in one file!

* Use role Pluggable to handle plugin modules. Delivered modules in the Sxml namespace can be handled this way.
* Use the resources field from META.info to save the core Sxml pluggable modules.

* And ...
  * Documentation.
  * Module and program documentation
  * Documentation is started as a docbook 5 document. There are references to local iconfiles and fonts for which I don't know yet if they may be included (license issues).
  * Tutorials.
