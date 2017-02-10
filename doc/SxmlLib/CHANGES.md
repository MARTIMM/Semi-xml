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

## Epub3
* EPub3::Builder - Build an Epub3 document. See also http://www.jedisaber.com/eBooks/formatsource.shtml
  * 0.1.0
    * Generate directory structure
    * Generate mimetype
    * Generate META-INF/container.xml

## Html
* SxmlLib::Html::List - Html lists like ul/li
  * dir-list() to recursively create list of files and directories.

## Testing
* 0.2.1
  * **Temporary problem fix in Report module when %\*RESOURCES is used. When program sxml2xml is using the modules via lib instead of the installed ones the path is missing the root directory name of this project. This might be a perl6 problem but I haven't seen it yet in other projects of mine.**
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
