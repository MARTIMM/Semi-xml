# Bugs and Todo list for the SemiXML::* modules and sxml2xml program

* Parser and actions.
  * Error messages when parser fails can still be improved.

* Syntax
  * XML element name can contain any alphanumeric characters. The only punctuation mark allowed in names are the hyphen '-', underscore '\_' and period '.'. Xml namespaces are separated by a colon ':'. These characters can not be used to start an element or to separate a module key from its method.

```
      Current syntax          Becomes             Note    Done

      $|xyz []                $xyz                        x
      $|xyz [x]               $xyz [x]            2       x

      $*|inline [x]           $inline [x]         1,3
      $|*inline [x]           $inline [x]         1,3
      $**inline [x]           $inline [x]         1,3

      $|nonnest [! x !]       $nonnest [x]        3,5
      $|spcresrv [= x ]       $spcresrv [x]       3,5

      $!key.method [x]        Remains the same    4

```
  Notes;
  * 1) `$*|`, `$|*` and `$**` might still be used when other spacing around elements is desired then the configuration prescribes. These will then mean; add space to the left, add space to the right and add spaces to the left and right resp.
  * 2) `$|` can also be used now to change spacing around elements when needed. Here the meaning is to remove all spacing around the element.
  * 3) The configurtion will be searched for those elements which are inline and need a special treatment of spacing around elements. Also nonnestable and space reserving elements are searched for in the configuration. The inline elements must also check for some non-alphanumeric characters following the block. E.g. in case of `,` or `.` etc. no space should be placed between the block and the following character.
  * 4) The key is a label mapped to the module in the configuration. The method must of course be available in that module. Need to think about how to communicate the way spacing needs to be done around the result of the call. Perhaps a method in the module like `method is-method-inline ( Str $method-name --> Bool ) { }` returning True or False for handling top level element as inlining or block element. When method is unavailable it is always assumed False. A long name is chosen to prevent name clashes. An example is made in SxmlCore but not called yet from the Actions module.
  * 5) The space reserving '=' and non nesting '!' characters at the start of a block does not have to be removed completely but can just be used ocasionally in case it is needed in a particular situation. E.g. To write css text it is not needed to have a space reserving block of text. However, to check the result, it is better to view it in a readable format.

* External modules located in SxmlLib tree
  * Library paths to find modules are provided
  * A module should be accessable from within another perl6 sxml module. Problem of registration.
  * Use a plugin system for the modules.
  * Store SxmlLib modules in the resources directory.

* attribute grammar addition for boolean =x =!x or even change into named attributes of perl. Possible to have hashes, array and more. Values will always be string or perhaps boolean. 

* Items needed in program sxml2xml or SemiXML/Sxml.pm6
  * Dependencies on other files
  * Store internal representation back into sxml.
  * Load any xml based source to convert back to sxml. Can be used as a start for templating things using pages from a nice website.
  * Add conveneance method to Sxml.pm6 to process %attrs for class, id, style etc. and add those to the provided element node. Then remove them from %attrs. `method std-attrs ( XML::Element $e, %attrs ) { }`

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
    # [C] Content definition table. only used with out-key and file. Looked up after parsing to prefix data to result.
    [ C ]
    [ C.out-key ]
    [ C.out-key.file ]

    # [D] Dependencies table, only with in-key. The file
    # is used to delect the array of files on which this
    # file depends. Looked up before everything is
    # started. Used by sxml2xml program.
    [ D ]
    [ D.in-key ]
      file = [ f1, f2, f3, ...]

    # [E] Entity table. Only with out-key and file.
    # Looked up after parsing to prefix data to result.
    [ E ]
    [ E.out-key ]
    [ E.out-key.file ]

    # [H] Http table, only with out-key and file. Looked up after parsing.
    [ H ]
    [ H.in-key ]
    [ H.in-key.file ]

    # [ML] Combined module and library table. Only with in-key and file.
    # Looked up just before parsing.
    [ ML ]
    [ ML.in-key ]
    [ ML.in-key.file ]
      mod-key = 'Module[;library]'

    # [R] Run table only with in-key and file. The out-key is used to select
    # the command line. Looked up after parsing. Used to send the total (after
    # looking into D and E) to a program further processing instead of saving
    # it to disk.
    [ R ]
    [ R.in-key ]
    [ R.in-key.file ]
      out-key = 'command line'

    # [S] Storage table, only with file. Looked up after parsing.
    [ S ]
    [ S.file ]

    ```
  All these ideas could also replace the one option --run from the program which only had a selective influence on the [output.program] table. Also less files might be searched through as opposed to the list shown above.

* Use role Pluggable to handle plugin modules. Delivered modules in the Sxml namespace can be handled this way.
* Use the resources field from META.info to save the core Sxml pluggable modules.

* And ...
  * Documentation.
  * Module and program documentation
  * Documentation is started as a docbook 5 document. There are references to local iconfiles and fonts for which I don't know yet if they may be included (license issues).
  * Tutorials.
