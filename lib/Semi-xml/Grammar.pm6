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
#  token tag-name { ( '$.' || '$!' || '$' ) <identifier> }
  token tag-name { <tag-type> <identifier> }
  token tag-type {   ('$.' <identifier> '.' )
                  || ('$!' <identifier> '.' )
                  || '$'
                 }
                  

  # The tag may be followed by attributes. These are key=value constructs. The
  # key is an identifier and the value can be anything. Enclose the value in
  # quotes ' or " when there are whitespace characters in the value.
  # 
  token attribute { <attr-key> '=' <attr-value-spec> }
  token attr-key { <identifier> }
  token attr-value-spec { \' <attr-value> \'
                          || \" <attr-value> \"
                          || <attr-value>
                        }
  token attr-value { <-[\s]>+ }

  # The tag body is anything enclosed in [...], [=...] or [-...]. The first
  # situation is the normal one of which all spaces will be reduced to one
  # space and leading and trailing spaces are removed. The second form is
  # used to save spacing as is. The third will not accept any child elements
  # so the $ sign is free to use without escaping it. Useful to insert
  # javascript code. ] and # still needs to be escaped when needed. To keep the
  # content of [- ...] also as is written write [+ ...].
  #
  rule tag-body { <normal-body> }

  # Changed from rule into token because of body character '[' followed up with
  # optional '+', '-' and '=' may not be separated by a space. Then content
  # starting with a those characters doesn't have to be escaped when they are
  # used. Just use a space in front. Can happen in tables showing numbers.
  #
  token normal-body { <body-start> ~ <body-end> <body-contents> }
  token body-start { '[' }
  token body-end { ']' }

  # The content can be anything mixed with document tags except following the
  # no-elements character. To use the brackets and
  # other characters in the text, the characters must be escaped.
  #
  rule body-contents {    ( <no-elements> || <no-elements-literal> )
                          ( <no-elements-text> )*
                       || <keep-literal>? ( <body-text> || <document> )*
                     }

  token keep-literal { '=' }
  token no-elements { '-' }
  token no-elements-literal { '+' }
  token body-text { ( <-[\$\]\\]> || <body-esc> )+ }
  token no-elements-text { ( <-[\]\\]> || <body-esc> )+ }
  token body-esc { '\$' || '\[' || '\]' || '\\' }

  # See STD.pm6 of perl6. A tenee bit simplefied. .ident is precooked and a
  # dash within the string is accepted.
  #
  token identifier { <.ident> [ '-' <.ident> ]* }
}
