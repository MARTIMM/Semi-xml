
The project is still at omega state, bugs come and go (hopefully).

* If dir and file is ```X/abc.sxml``` and there is a prelude used with ```output/filename: index;```, then running the file the result file come at the right spot. Depending on the default, the result will come in dir X. Using ```output/filename: ../index;``` the result will come in the directory below the users directory. Need to think about this what is best. Maybe add a config item, something like filepath.

* At the moment it is too complex to handle removal of a minimal indentation in pieces of text which must be kept as is typed. Needed in e.g. tags pre in html or programlisting in docbook. The complexity is caused by using child elements in such tags.

* All indents of generated documents should unindented to proper level are reduced to the minimum spacing as is done in perl6.

* Top level tags cannot be a method or substitution.

* Comments are not properly handled. At the moment they are removed from the grammar.

* Pipes to programs can now be implemented!

* Use Config::DataLang::Refine to get the info from loaded hashes.

* Since the new changes, nested commands $!x.y1 [ $!x.z [ ]] will not work.
