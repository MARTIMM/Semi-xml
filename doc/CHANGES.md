## Changes

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
