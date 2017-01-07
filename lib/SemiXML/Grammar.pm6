use v6.c;
#use Grammar::Tracer;

unit package SemiXML:auth<https://github.com/MARTIMM>;

grammar Grammar {

  rule init-doc { <?> }
  rule TOP {
    <.init-doc> <.comment>* <document> <.comment>* 
  }

  # A document is only a tag with its content. Defined like this there can
  # only be one toplevel document.
  #
  rule pop-tag-from-list { <?> }
  rule document {
#    <.comment>*
    <tag-spec> <tag-body>*
#    <.comment>*
    <.pop-tag-from-list>
  }

  # A tag is an identifier prefixed with a symbol to attach several semantics
  # to the tag.
  #
  rule tag-spec { <tag> <attributes> }

  proto token tag { * }
  token tag:sym<$!>   { <sym> <mod-name> '.' <meth-name> }
  token tag:sym<$|*>  { <sym> <tag-name> }
  token tag:sym<$*|>  { <sym> <tag-name> }
  token tag:sym<$**>  { <sym> <tag-name> }
  token tag:sym<$|>   { <sym> <tag-name> }

  token mod-name      { <.identifier> }
  token sym-name      { <.identifier> }
  token meth-name     { <.identifier> }
  token tag-name      { [ <namespace> ':' ]? <element> }
  token element       { <.identifier> }
  token namespace     { <.identifier> }

  # The tag may be followed by attributes. These are key=value constructs. The
  # key is an identifier and the value can be anything. Enclose the value in
  # quotes ' or " when there are whitespace characters in the value.
  #
  token attributes    { [ <.ws>? <attribute> ]* }

  token attribute     { <attr-key> '=' <attr-value-spec> }

  token attr-key      { [<.key-ns> ':' ]? <.key-name> }
  token key-ns        { <.identifier> }
  token key-name      { <.identifier> }

  token attr-value-spec {
    [\' $<attr-value>=<.attr-q-value> \']  ||
    [\" $<attr-value>=<.attr-qq-value> \"] ||
    [\^ $<attr-value>=<.attr-pw-value> \^] ||
    $<attr-value>=<.attr-s-value>
  }
  token attr-q-value  { [ <.escape-char> || <-[\']> ]+ }
  token attr-qq-value { [ <.escape-char> || <-[\"]> ]+ }
  token attr-pw-value { [ <.escape-char> || <-[\^]> ]+ }
  token attr-s-value  { [ <.escape-char> || <-[\s]> ]+ }

  token tag-body { [
      '[!=' ~ '!]'    <body1-contents> ||
      '[!' ~  '!]'    <body2-contents> ||
      '[=' ~   ']'    <body3-contents> ||
      '[' ~    ']'    <body4-contents>
    ]
  }

  # The content can be anything mixed with document tags except following the
  # no-elements character. To use the brackets and other characters in the
  # text, the characters must be escaped.
  #
  rule body1-contents  { <body2-text> }
  rule body2-contents  { <body2-text> }
  rule body3-contents  { [ <.comment> || <body1-text> || <document> ]* }
  rule body4-contents  { [ <.comment> || <body1-text> || <document> ]* }

  token body1-text {
    [ <.escape-char> ||         # an escaped character e.g. '\$'
      <-[\$\]\#]> ||            # any character not being '$', '#' or ']'
      '$' <!before <[!|*]>>     # a $ not followed by '!', '|' or '*'
    ]+
  }

  token escape-char        { '\\' . }

  # No comments allowed in [! ... !]. This works because a nested document is
  # not allowed and thus no extra comments are checked and handled as such..
  token body2-text      { [ .*? <?before <.ws>? '!]'> ] }

  # See STD.pm6 of perl6. A tenee bit simplefied. .ident is precooked and a
  # dash within the string is accepted.
  #
  token identifier { <.ident> [ '-' <.ident> ]* }

  token comment { \h* '#' \N* \n }
}

