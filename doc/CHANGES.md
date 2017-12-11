[toc]

# Changes in SemiXML:: * and sxml2xml

Future changes regarding modules in SxmlLib are recorded in SxmlLib/Changes.md with their own version numbers

* 0.39.0
  * Added --force to sxml2xml and :force to Sxml.pm6 BUILD() to force processing even when result is newer than its source. This is for example needed when developing modules. The sxml source might not change while coding the module.
* 0.38.0
  * Added a remapping option to move inserted content to some other location at the end of the parsing process.
* 0.37.0
  * Added a new module to generate a menu
* 0.36.0
  * Added modules to support css and generating colors
* 0.35.0
  * Added a way to insert and substitute variables.
* 0.34.0
  * Dependency table can have entries of files where the IN- and OUT-keys are a '-'. If defined like that, there is no extra processing but only the test if the target file is older than the depending file. This can be used if a module is changed or an image is updated.
* 0.33.2
  * In SxmlLib::Html::List the use of `dir\( \$d, :str)` has changed in newer versions of perl6. Can now be done like `dir\(\$d)>>.Str`.
  * The type `ParseResult` is removed. parse() now returns a Bool to show that a file is parsed correctly (`True`) or skipped (`False`) because of its result being newer. It throws an exception when parsing fails.
* 0.33.1
  * Improved processing of dependencies
  * A dependency entry may also be a string instead of an array of strings when only one file is involved
* 0.33.0
  * Implemented self-closing key of table F in configuration.
* 0.32.0
  * --trace is removed. All tracing is controlled by config table T and by config entry tracing (true/false) in the C table.
  * Dependencies upon other files is conrolled by config table D.
  * Parsing and saving is done only after check of result modification time against the source file.
* 0.31.0
  * sxml2xml.pl6 knows about options --in, --out and --trace. --run is removed.
  * Configuration completely changed using tables and refinements on these tables using the in and out refinement keys.
  * config key ```rootpath``` in S-table added.
* 0.30.0
  * Boolean attributes as =attr and =!attr meaning attr=1 and attr=0 resp.
* 0.29.0
  * Added attribute value type list to write like a=<v1 v2 v3>. Attributes are stored in StringList class now with a boolean 'use-as-list' to control output.
  * StringList can do .value(), .List(), .Str(), .Bool(), new(), CALL-ME(), Int(), Numerical()
* 0.28.1
  * Added sub std-attrs to Sxml.pm6 to easily scan attrs and for id,class, style and the like and add those to the provided XML element. The attributes are then removed from the attrs hash.
  * Added new table entries to the default config file in preparation of later changes.
  * New configuration tables are implemented and refinable.
  * XML generating modules could use helper subs from SemiXML::Sxml. These subs are moved into a separate module SxmlLib::SxmlHelper.
* 0.28.0
  * **$|element [ ]** is changed into **$element [ ]**.
* 0.27.5
  * Rewrote parts of SxmlLib::SxmlCore. Added options to some methods and removed others.
  * sxml2xml.pl processing of commandline options changed to cope with info from #! line in the sxml file.
  * Pod doc for SxmLib::SxmlCore.
* 0.27.4
  * Rewrote some parts of Sxml.pm6 to handle the configuration, it is much better now.
  * parse-file is changed into parse. Together with the original one they are now defined as multi methods.
  * %?RESOURCES problem is fixed. It depends on PERL6LIB env variable.
* 0.27.3
  * refactored SemiXML::Text from Actions to SemiXML/Text.pm6.
  * long standing bug fixed: Resources gave wrong path when using local distro. Caused by the way the Sxml class was defined. file SemiXML.pm6 is now moved to SemiXml/Sxml.pm6 and all use statements are modified.
  * **Temporary problem fix in Report module when %\*RESOURCES is used. When program sxml2xml is using the modules via lib instead of the installed ones the path is missing the root directory name of this project. This might be a perl6 problem but I haven't seen it yet in other projects of mine.**
* 0.27.2
  * indentation in fixed areas like for pre(html) or programlisting(docbook) noted by [= ...] is minimized. Now it is not necessary anymore to place your fixed text at the begin of the line.
  * refactored the SxmlCore class from SxmlLib::Actions to a new file SxmlLib/SxmlCore.pm6. It is also not automatically declared anymore in the module table so users must add it to the module table in their config.
  * refactored method get-current-filename() from Actions to Sxml class.
* 0.27.1
  * standalone attribute added to xml prelude usable from toml config
* 0.27.0
  * Added a sub save-xml() to save an XML document to disk
  * Use of :formatted to this sub will format the xml output using the xmllint program and its -format option. Dunno how to use that in windows however. Default is off.
* 0.26.5
  * More locations where comments are allowed.
  * Better location information when parsing fails.
* 0.26.4
  * Better search for config files. done in one place instead of two.
* 0.26.3
  * bugfixes in finding config files
* 0.26.2
  * Added run option fmt to format output for better reading. use as ```sxml2xml --run=fmt abc.sxml```.
  * Error messages to the commandline instead of log file
  * Google highlighting code for code snippets in test report module. Files are installed locally in the resources directory.
* 0.26.1
  * More output when generating reports in SxmlLib::Testing::Testing::Report
* 0.26.0
  * Implemented the skip part of the report generator.
  * Change in processing configuration files.
  * Implemented comments in normal bodies [ ... ].
* 0.25.0
  * Before there was only one content block per element specification like ```$abc [some text]```. Now it is possible to have 0, 1 or more blocks following a tag so the following is possible;
  ```
  $|a
  $|b [ hgf $|xyz ]
  $|c [ code: ][! $j = $delta * 10 !]
  ```
  which generates
  ```
  <a/>
  <b>hgf <xyz/></b>
  <c>code: $j = $delta * 10</c>
  ```
* 0.24.0
  * Change in grammar. ```$xyx []``` has become ```$|xyz []```. This is a big help when code with many dollar characters are used. These should be escaped but wil make things unreadable. Also using the [! !] bodies are not always acceptable because it prevents nesting of elements when needed. So this can now be done; ``` $|abc [ $x = 10; ] ```
* 0.23.0
  * Dropped the use of $.mod.symbol-access. There is less to none use for it.
  * Add optional initializing() method to sxml modules ($!) with the attributes and SemiXML::Sxml object. These are called as soon as the tag and attributes are parsed. Later when the body is parsed the call to the method of that module is called.
  * Add get-sxml-object('class name') to Actions class
  * Add get-sxml-object handle in SemiXML::Sxml to call method.
* 0.22.0
  * Added module to make test reports. It gives the possibility to describe the tests and define them as well as run them. The results are shown at the end of the generated document and also written into a metric file. This will be used to make a summary report.
* 0.21.0
  * Refitted the piping to external commands
* 0.20.0
  * Complete rewrite of grammar and actions
  * A primitive parse error locater is implemented.
  * A change in tag types: $\*, $\*> and $\<* are now $\*\* $\*| and $|\* resp.
  * Simple tests are setup in 010-simple.t testing $x $\*\*x $\*|x and $|\*x
  * Substitution type $.x re-implemented
  * Method type $!x re-implemented.
  * Escape character processing, e.g. '>' conversion to \&gt; is done as late as possible for attributes as well as textual content.
* 0.19.0
  * Replaced prelude and internal configs with Config::DataLang::Refine
  * Roles are dropped for adding configs.
  * Extra configs can be provided via the parse() method when there is no file involved.
  * Method process-config-for-modules added to Actions to take care for modules found in the config. This will change later!
* 0.18.0
  * Changed module name from Semi-xml into SemiXML. Changes reflected all files
  and other module names.
* 0.17.0
  * Many changes because of perl6 changes until the end of 2015. Big changes are removal of EVAL() statements and the updates of used perl6 version which is now v6.c. Furthermore there were some bug fixes where code was manipulating the XML nodes. Added also a helper function to find the PLACEHOLDER-ELEMENT.
* 0.16.3 Bugfixes in code and tests
* 0.16.2
  * Small changes in the grammar to slim down the match object during parsing. E.g. ```<comment>``` subrules are changed into ```<.comment>``` which will prevent storing information about the capture in the match object.
  * Bugfixes in test code. Initializing ```Semi-xml``` objects into ```Semi-xml::Sxml```.
* 0.16.1
  * Input of unicode characters by html codes, unicode codepoints, utf8 codes or literal characters. E.g. &#x01E3;, \u01E3, \xC7A3, ǣ
* 0.16.0
  * Adding modules to output formatted text read from files. There is one for Html and one for Docbook 5.
* 0.15.0
  * Output of http header
* 0.14.4
  * Change way comments are processed. Needs some extra work.
* 0.14.3
  * File.pm6 had a bug which didn't include the files anymore. Unknown how and why it was intrduced.
  * Bugfix of spacing around tags. One too many modifications of XML::Text into Semi-xml::Text.
* 0.14.2
  * Added a trick from the panda program to reorder the options to the front so the sxml files can be made executable and on the commandline some added options which would come after the filename instead of before.
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
* 0.4.1
  * Bugfix attribute handling
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

# Changes in SxmlLib modules. Shown below separately

## Docbook5
* SxmlLib::Docbook5::Basic - Basic docbook methods
  * 0.3.1
    * in basic module the article and book methods should generate proper namespace names, i.e. xlink instead of xl.
  * 0.3.0
    * docbook 5 email added to info
  * 0.2.0
    * book() and article() methods to start easy with a lot of attributes.
  * 0.1.0
    * info() to specify the elaborate info tag.

## Epub 2 and 3

  * 0.4.1
    * EPub.pm6 to put commonalities for version 2 and 3 in.
    * Generate zip and open with sigil, calibre etc.
    * Version will become that of EPub.pm6 module.
  * 0.4.0
    * EPub::Epub2Builder - Build an Epub2 document. See also http://www.jedisaber.com/eBooks/formatsource.shtml and http://idpf.org/epub
    * Copy from EPub::Epub3Builder and make changes.
  * 0.3.0
    * Generating navigation document
  * 0.2.0
    * Generate package config in content.opf. It contains metadata, manifest and spine
    * Files are copied from workdir into Build-dir.
  * 0.1.0
    * Generate directory structure in build-dir.
    * Generate mimetype
    * Generate META-INF/container.xml
    * EPub::Epub3Builder - Build an Epub3 document. See also http://idpf.org/epub

## Html
* SxmlLib::Html::List - Html lists like ul/li
  * dir-list() to recursively create list of files and directories.

## Testing

* 0.2.2
  * Metric file fitering on provided labels in tests
* 0.2.1
  * Implemented test summary reports
* 0.2.0
  * Code numbering in report is following lines in the real test program so it is possible to look in your report at the proper line with the information from the test output.
  * Indenting is per 4 characters instead of two.
* 0.1.1
  * Downloaded wrong files for the google prettify
  * Bugfix removing hook elements from the resulting document
* 0.1.0 Version set on 2016-12-12. Modules comprising Bug, Code, Report, Skip, Test, Testing and Todo


# Other modules independent of xml languages

### File
* include() other documents.

### LoremIpsum

### SxmlCore

* A Sxml core library included by default to handle simple items like
  * comment() for comments <!-- ... -->.
  * PI() for <?...?>.
  * CData() for <[CDATA[...]]>.
  * date() for date
  * date-time() for datetime.
