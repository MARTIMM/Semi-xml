use v6;
#use Grammar::Tracer;

grammar Semi-xml::Grammar {
  token TOP { <document> }
  token document { \s* <tag> \s* <tag-body> \s* }

  token tag { '$' <ident> <attributes>* }

  token tag-body { '[' ~ ']' <body-contents> }
#  token body-start { '[' }
#  token body-end { ']' }
  token body-contents { ( <-[\$\]]> || <document> )* }

#  token tag-id { <[A..Za..z\_]>  <[A..Za..z0..9\_\-]>* }
  token attributes { \s* <attr-key> '=' <attr-value> }
  token attr-key { <[A..Za..z\_]>  <[A..Za..z0..9\_\-]>* }
  token attr-value { \' <-[\']>+ \' || \" <-[\"]>+ \" || <-[\s]>+ }

#  token data { .*? ( <?th-end> || <?td-end> ) }

#  token tag-id { <[A..Za..z\_]> ( <[A..Za..z0..9\:\_\-]>*
#                                  <[A..Za..z0..9\_]>
#                                )*
#               }
}
