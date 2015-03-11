use v6;
#use Grammar::Tracer;

grammar Semi-xml::Grammar {

  # A complete document looks like the following of which the prelude an dashes
  # are optional
  #
  # ---
  # prelude
  # ---
  # document
  #
  rule TOP { ( "---" <prelude> "---" ) ** 0..1 <document> }
  
  # The prelude is a series of configuration options looking like
  #
  # /x/y/opt:  value;
  #
  rule prelude { <config-entry>* }
  rule config-entry { <config-keypath> ':' <config-value> ';' }
  token config-keypath { <config-key> ( '/' <config-key> )* }
  token config-key { <identifier> }
  rule config-value { <-[;]>+ }
  
  # A document is only a tag with its content. Defined like this there can only
  # be one toplevel document.
  #
  rule document { <tag> <tag-body> }

  # A tag is an identifier prefixed with $. $! or $ to attach several semantics
  # to the tag.
  #
  # $table class=bussiness id=sect1 
  #
  rule tag { <tag-name> ( <attribute> )* }
  token tag-name { ( '$.' || '$!' || '$' ) <identifier> }

  # The tag may be followed by attributes. These are key=value constructs. The
  # key is an identifier and the value can be anything. Enclose the value in
  # quotes ' or " when there are whitespace characters in the value.
  # 
  token attribute { <attr-key> '=' <attr-value-spec> }
  token attr-key { <identifier> }
  token attr-value-spec { \' <attr-value> \' || \" <attr-value> \" || <attr-value> }
  token attr-value { <-[\s]>+ }

  # The tag body is anything enclosed in [...] or |[...]|. The first situation
  # is the normal one of which all spaces will be reduced to one space and
  # leading and trailing spaces are removed. The second form is used to save
  # spacing as is.
  #
  rule tag-body { <normal-body> || <lit-body> }

  rule normal-body { <body-start> ~ <body-end> <body-contents> }
  token body-start { '[' }
  token body-end { ']' }

  rule lit-body { <lit-body-start> ~ <lit-body-end> <body-contents> }
  token lit-body-start { '|[' }
  token lit-body-end { ']|' }

  # The content can be anything and new document tags. To use the brackets and
  # other characters in the text, the characters must be escaped.
  #
  token body-contents { ( <body-text> || <document> )* }
  token body-text { ( <-[\$\]\\]> || <body-esc> )+ }
  token body-esc { '\$' || '\[' || '\]' || '\\' }

  # See STD.pm6 of perl6. A tenee bit simplefied. .ident is precooked and a
  # dash within the string is accepted.
  #
  token identifier { <.ident> [ '-' <.ident> ]* }
}
