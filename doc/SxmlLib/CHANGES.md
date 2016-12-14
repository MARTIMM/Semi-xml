# Changes in SxmlLib modules. Shown below separately

## Docbook5
* SxmlLib::Docbook5::Basic - Basic docbook methods
  * book() and article() methods to start easy with a lot of attributes.
  * info() to specify the elaborate info tag.

## Html
* SxmlLib::Html::List - Html lists like ul/li
  * dir-list() to recursively create list of files and directories.

## Testing
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
