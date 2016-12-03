
The project is still at omega state, bugs come and go (hopefully).

* At the moment it is too complex to handle removal of a minimal indentation in pieces of text which must be kept as is typed. Needed in e.g. tags pre in html or programlisting in docbook. The complexity is caused by using child elements in such tags.

* All indents of generated documents should be unindented to proper level and reduced to the minimum spacing as is done in perl6 here docs.

* Comments are not properly handled. At the moment they are removed from the grammar.

* Pipes to programs can now be implemented!

* Use Config::DataLang::Refine to get the info from loaded hashes.
