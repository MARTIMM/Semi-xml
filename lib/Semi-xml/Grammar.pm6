use v6;
#use Grammar::Tracer;

grammar Semi-xml::Grammar {
#  token TOP { <ws> <document> <ws> }
#  token document { <ws> <tag> <ws> <tag-body> <ws> }
  rule TOP { ("-p-\n" <prelude> "---\n" ) ** 0..1 <document> }
  rule prelude { ( <config-key> ':' <config-value> ';' )* }
  rule config-key { <identifier> ( '/' <identifier> )* }
  rule config-value { <-[;]>+ }
  
  rule document { <tag> <tag-body> }

  token tag { <tag-name> <attribute>* }
  token tag-name { '$' <identifier> }

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

  # See STD.pm6 of perl6. A tenee bit simplefied
  #
  token identifier { <.ident> [ '-' <.ident> ]* }
}
