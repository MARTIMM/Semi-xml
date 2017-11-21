# Bugs and Todo list for the SemiXML:: * modules and sxml2xml program

# Bugs
Attribute values which are empty like '' or "" are translated wrong
* '' -> "''"              Now fixed
* "" -> '&quot;&quot;"    Now fixed

# Todo

## Parser and actions.
* Error messages when parser fails can still be improved.

## Syntax
* XML element name can contain any alphanumeric characters. The only punctuation mark allowed in names are the hyphen '-', underscore '\_' and period '.'. Xml namespaces are separated by a colon ':'. These characters can not be used to start an element or to separate a module key from its method.

```
      Current syntax          Becomes             Note    Done

      $|xyz []                $xyz                        x
      $|xyz [x]               $xyz [x]            2       x

      $*|inline [x]           $inline [x]         1,3
      $|*inline [x]           $inline [x]         1,3
      $**inline [x]           $inline [x]         1,3

      $|nonnest [! x !]       $nonnest [x]        3,5     ?
      $|spcresrv [= x ]       $spcresrv [x]       3,5

      $!key.method [x]        Remains the same    4
                              or perhaps $key:method.

```
* Notes;
  1) `$*|`, `$|*` and `$**` might still be used when other spacing around elements is desired then the configuration prescribes. These will then mean; add space to the left, add space to the right and add spaces to the left and right resp.

  2) `$|` can also be used now to change spacing around elements when needed. Here the meaning is to remove all spacing around the element.

  3) The configuration will be searched for those elements which are inline and need a special treatment of spacing around elements. Also non nest-able and space reserving elements are searched for in the configuration. The inline elements must also check for some non-alphanumeric characters following the block. E.g. in case of `,` or `.` etc. no space should be placed between the block and the following character.

  4) The key is a label mapped to the module in the configuration. The method must of course be available in that module. Need to think about how to communicate the way spacing needs to be done around the result of the call. Perhaps a method in the module like `method is-method-inline ( Str $method-name --> Bool ) { }` returning True or False for handling top level element as in-lining or block element. When method is unavailable it is always assumed False. A long name is chosen to prevent name clashes. An example is made in SxmlCore but not called yet from the Actions module.

  5) The space reserving '=' and non nesting '!' characters at the start of a block does not have to be removed completely but can just be used occasionally in case it is needed in a particular situation. E.g. To write css text it is not needed to have a space reserving block of text. However, to check the result, it is better to view it in a readable format.

* Addition of several types of comments
  * [x] **# \<text> EOL**. Comments are removed and can only be used at top level and in **\$x [ ]** parts. Not within **\$x [! !]**.
  * [x] Generated XML Comments using **\$!SxmlCore.comment [ ]**.
  * [ ] Javascript and css like comments **// \<text> EOL** and **/\* \<text> \*/**. Can be used only within **\$x [! !]** and special checks must be done for these character strings within string variable values.
  * [ ] Simple perl6 forms like **#`{{ \<text> }}**. Can be used everywhere.

## External modules located in SxmlLib tree
* Library paths to find modules are provided
* A module should be accessible from within another perl6 sxml module. Problem of registration.
* Use a plugin system for the modules.
* Store SxmlLib modules in the resources directory.

## Attribute grammar addition
* Boolean attributes can be expressed as **=x** and  **=!x** meaning **x=true** or **x=false**.
* Attributes are also given as argument to module methods. In this case it might be possible to have hashes, array and more. Values are string or perhaps boolean.

## Items needed in program sxml2xml or SemiXML/Sxml.pm6
  * Dependencies on other files
  * Store internal representation back into sxml.
  * Load any xml based source to convert back to sxml. Can be used as a start for templating things using pages from a nice website.
  * Add conveneance method to Sxml.pm6 to process %attrs for class, id, style etc. and add those to the provided element node. Then remove them from %attrs. `method std-attrs ( XML::Element $e, %attrs ) { }`

## Tests
  * tags without body but with attributes
  * comments in sxml
  * lineup of brackets of body to find errors

## Configuration
  * Search for config files (assume parsed file is fpath/file.sxml)
    * Merge <resource-location>/<resource named SemiXML.toml>,  <fpath>/SemiXML.toml, ~/.SemiXML.toml, ./.SemiXML.toml, ./SemiXML.toml, <fpath>/file.toml, ~/.file.toml, ./.file.toml and ./file.toml

  * When choosing the proper command line options one must keep the following in mind. First the document written is always **sxml**. What it represents should be the first option (by default **xml**) and what it should become the next option (by default **xml**). These options are provided by the sxml2xml program. The following **--in** and  **--out** with e.g. **--in=docbook5** and  **--out=pdf**. This way the configuration can describe what should be done with, for example, the xml prelude, the doctype declaration or which command to select to get the result. To also use the refine method from Config::DataLang::Refine, the options are used as keys to that method. A third key can be added, the basename of the file being parsed. So the next configuration tables are possible ();

    ```
    # [C] Content additions table. only used with out-key and file. Looked
    # up after parsing to prefix data to result. Used for booleans to control
    # inclusion of XML description(X table), doctype(E table) and message
    # header(H table)
    [ C ]
    [ C.out-key ]
    [ C.out-key.file ]

    # [D] Dependencies table, only with in-key. The file is used to
    # specify the array of files on which this file depends.
    # Looked up before everything is started. Used by sxml2xml program.
    [ D ]
    [ D.in-key ]
    out-key = [ 'dep-file in-key;dep-file out-key;dep-file', ...]
    out-key = 'dep-file in-key;dep-file out-key;dep-file'

    # [E] Entity table. Only with in-key and file.
    # Looked up after parsing to prefix data to result.
    [ E ]
    [ E.in-key ]
    [ E.in-key.file ]

    # [F] Formatting table. Used to control formatting of text. Used while
    # parsing and translating.
    [ F ]
    [ F.in-key ]
    [ F.in-key.file ]

    # [H] Http table, only with out-key and file. Looked up after parsing.
    [ H ]
    [ H.out-key ]
    [ H.out-key.file ]

    # [ML] Combined module and library table. Only with in-key and file.
    # Looked up just before parsing.
    [ ML ]
    [ ML.in-key ]
    [ ML.in-key.file ]
      mod-key = 'Module[;library]'

    # [R] Run table only with in-key and file. The run-key is used to select
    # the command line. Looked up after parsing. Used to send the total
    # finished document to a program for further processing instead of saving
    # it to disk.
    [ R ]
    [ R.in-key ]
    [ R.in-key.file ]
      run-key = 'command line'

    # [S] Storage table, only with file. Looked up after parsing.
    [ S ]
    [ S.out-key ]
    [ S.out-key.file ]

    # [T] Trace table. Does not use in or out keys, only the filename
    [ T ]
    [ T.file ]

    # [X] xml description table
    [ X ]
    [ X.out-key ]
    [ X.out-key.file ]

    ```
  All these ideas could also replace the one option --run from the program which only had a selective influence on the [output.program] table. Also less files might be searched through as opposed to the list shown above.
  This is now implemented.

## Plugin modules
* Use role Pluggable to handle plugin modules. Delivered modules in the Sxml namespace can be handled this way.
* Use the resources field from META.info to save the core Sxml plug-able modules.

## Modules
* Handle and generate ebooks
* Support docbook 5
* Support html
* Support css
* Support perl6 module testing

## Module ideas
### css a la scss/sass
```
$!css.style [
  $!css.color-palette base='red' type=single-color []
  $!css.b s='.infobox >' [
    $!css.b s=.message [
      border: 1px solid $step4;
      $!css.b s='> .title' [
        color: $step8;
      ]
    ]
    $!css.b s=.user [
      border: 1px solid black;
      $!css.b s='> .title' [
        color: black;
      ]
    ]
  ]
]
```
Normally **\$step8** will produce **\<step8 />** but **\$!css.style** can find them in its content and use them as variables generated by $!css.color-palette and substitute them with their values like `#880000`.

The code above could produce (This will be more like a one liner, but is pretty printed here)

```
<style>
.infobox > .message {
  border: 1px solid #440000;
 }

.infobox > .message > .title
  color: #880000;
 }

.infobox > .user {
  border: 1px solid black;
}

.infobox > .user > .title {
  color: black;
}
</style>
```

### Variables
This might be defined in the main libs. An example;
```
$!SxmlCore.var name=aCommonText [Lorem ipsum dolor simet ...]
```
That piece could set a variable and any use of **\$aCommonText** would then be substituted by the variable value `Lorem ipsum...` instead of translating it into **\<aCommonText />**. A module should also be able to set a variable.

Scope?


## And ...
  * Documentation.
  * Module and program documentation
  * Documentation is started as a docbook 5 document. There are references to local iconfiles and fonts for which I don't know yet if they may be included (license issues).
  * Tutorials.

<!-- References -->
[colors1]: http://paletton.com
[colorspace]: https://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
[colors2]: http://devmag.org.za/2012/07/29/how-to-choose-colours-procedurally-algorithms/
