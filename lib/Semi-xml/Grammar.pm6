use v6;
#use Grammar::Tracer;

grammar Semi-xml::Grammar {
#  token TOP { <ws> <document> <ws> }
#  token document { <ws> <tag> <ws> <tag-body> <ws> }
  rule TOP { <document> }
  rule document { <tag> <tag-body> }

  token tag { <tag-name> <attribute>* }
  token tag-name { '$' <ident> }

  rule tag-body { <body-start> ~ <body-end> <body-contents> }
  token body-start { '[' }
  token body-end { ']' }

  token body-contents { ( <body-text> || <document> )* }
  token body-text { ( <-[\$\]\\]> || <body-esc> )+ }
  token body-esc { '\$' || '\[' || '\]' || '\\' }

  token attribute { \s+ <attr-key> '=' <attr-value-spec> }
  token attr-key { <[A..Za..z\_]>  <[A..Za..z0..9\_\-]>* }
  token attr-value-spec { \' <attr-value> \' || \" <attr-value> \" || <attr-value> }
  token attr-value { <-[\s]>+ }
}
