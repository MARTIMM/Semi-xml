use v6;
#use Grammar::Tracer;

grammar Semi-xml::Grammar {
#  token TOP { <ws> <document> <ws> }
#  token document { <ws> <tag> <ws> <tag-body> <ws> }
  rule TOP { ( "---" <prelude> "---" ) ** 0..1 <document> }
  rule prelude { <config-entry>* }
  rule config-entry { <config-keypath> ':' <config-value> ';' }
  token config-keypath { <config-key> ( '/' <config-key> )* }
  token config-key { <identifier> }
  rule config-value { <-[;]>+ }
  
  rule document { <tag> <tag-body> }

  rule tag { <tag-name> ( <attribute> )* }
  token tag-name { ( '$' ) <identifier> }

  token attribute { <attr-key> '=' <attr-value-spec> }
  token attr-key { <[A..Za..z\_]>  <[A..Za..z0..9\_\-]>* }
  token attr-value-spec { \' <attr-value> \' || \" <attr-value> \" || <attr-value> }
  token attr-value { <-[\s]>+ }

  rule tag-body { <normal-body> || <lit-body> }

  rule normal-body { <body-start> ~ <body-end> <body-contents> }
  token body-start { '[' }
  token body-end { ']' }

  rule lit-body { <lit-body-start> ~ <lit-body-end> <body-contents> }
  token lit-body-start { '|[' }
  token lit-body-end { ']|' }

#  token body-contents { <style-def>? ( <body-text> || <document> )* }
  token body-contents { ( <body-text> || <document> )* }
  token body-text { ( <-[\$\]\\]> || <body-esc> )+ }
  token body-esc { '\$' || '\[' || '\]' || '\\' }

#  rule style-def { 'style' <style-body> }
#  rule style-body { <style-sets> || <lit-style-sets> }
#  rule style-sets { '[' ~ ']' ( <-[\s\]]>+ )* }
#  rule lit-style-sets { '|[' ~ ']|' ( <-[\s\]]>+ )* }

  # See STD.pm6 of perl6. A tenee bit simplefied
  #
  token identifier { <.ident> [ '-' <.ident> ]* }
}
