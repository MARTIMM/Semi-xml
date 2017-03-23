use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<https://github.com/MARTIMM>;

#use Grammar::Tracer;

#-------------------------------------------------------------------------------
grammar Grammar {

  # Actions initialize
  rule init-doc { <?> }

  # A document is only a tag with its content in a body. Defined like this
  # there can only be one toplevel document. In the following body documents
  # can be nested.
  #
  # Possible comments outside toplevel document
  rule TOP {
    <.init-doc>
    <.comment>*         # Needed to make empty lines between comments possible.
                        # Only here is needed body*-contents is taking care for
                        # the rest.
    <document>
    <.comment>*
  }

  # Rule to pop the current bottomlevel element from the stack. It is not
  # possible to use a rule to add the element to this stack. This happens in
  # the actions method for <tag-spec>.
  #
  rule pop-tag-from-list { <?> }
  rule document { <tag-spec> <tag-body>* <.pop-tag-from-list> }

  # A tag is an identifier prefixed with a symbol to attach several semantics
  # to the tag.
  #
  rule tag-spec { <tag> <attributes> }

  proto token tag { * }
  token tag:sym<$!>   { <sym> <mod-name> '.' <meth-name> }
  token tag:sym<$|*>  { <sym> <tag-name> }
  token tag:sym<$*|>  { <sym> <tag-name> }
  token tag:sym<$**>  { <sym> <tag-name> }
  #TODO token tag:sym<$|> { <sym> <tag-name> }
  token tag:sym<$>    { <sym> <tag-name> }

  token mod-name      { <.identifier> }
#  token sym-name      { <.identifier> }
  token meth-name     { <.identifier> }
  token tag-name      { [ <namespace> ':' ]? <element> }
  token element       { <.xml-identifier> }
  token namespace     { <.xml-ns-identifier> }

  # The tag may be followed by attributes. These are key=value constructs. The
  # key is an identifier and the value can be anything. Enclose the value in
  # quotes ' or " when there are whitespace characters in the value.
  #
  rule attributes    { [ <attribute> ]* }

  token attribute     {
    <attr-key> '=' <attr-value-spec>
# ||
#    '=' <attr-key> ||
#    '=!' <attr-key>
  }

  token attr-key      { [<.key-ns> ':' ]? <.key-name> }
  token key-ns        { <.identifier> }
  token key-name      { <.identifier> }

  token attr-value-spec {
    [ "'" ~ "'" $<attr-value>=<.attr-q-value> ]  ||
    [ '"' ~ "'" $<attr-value>=<.attr-qq-value> ] ||
#    [\^ $<attr-value>=<.attr-pw-value> \^] ||
    $<attr-value>=<.attr-s-value>
  }
  token attr-q-value  { [ <.escaped-char> || <-[\']> ]+ }
  token attr-qq-value { [ <.escaped-char> || <-[\"]> ]+ }
#TODO somewhere in a test the following is used
#  token attr-pw-value { [ <.escaped-char> || <-[\^]> ]+ }
  token attr-s-value  { [ <.escaped-char> || <-[\s]> ]+ }

  rule tag-body { [
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
  rule body3-contents  { [ <body1-text> || <document> || <.comment> ]* }
  rule body4-contents  { [ <body1-text> || <document> || <.comment> ]* }

  token body1-text {
    [ <.escaped-char> ||    # an escaped character
      <-[\$\]\#\\]>         # any character not being '\', '$', '#' or ']'
                            # to stop at escaped char, a document
                            # comment or end of current document.
    ]+
  }

  # No comments recognized in [! ... !]. This works because a nested documents
  # are not recognized and thus no extra comments are checked and handled as such.
  token body2-text      {
    [ <.escaped-char> ||    # an escaped character
      <-[\!\\]>             # any character not being '\' or '!'
                            # to stop at escaped char or end of
                            # current document
    ]+
  }

  token escaped-char     { '\\' . }
  #  token entity          { '&' <-[;]>+ ';' }

  # See STD.pm6 of perl6. A tenee bit simplified. .ident is precooked and a
  # dash within the string is accepted.
  token identifier { <.ident> [ '-' <.ident> ]* }

  # From w3c https://www.w3.org/TR/xml11/#NT-NameChar
  token xml-identifier { <.name-start-char> <.name-char>* }
  token name-start-char { ':' || <.ns-name-start-char> }
  token name-char { ':' || <.ns-name-char> }

  # From w3c https://www.w3.org/TR/2004/REC-xml-names11-20040204/#ns-decl
  token xml-ns-identifier { <.ns-name-start-char> <.ns-name-char>* }
  # Don't know which characters are covered by the :Alpha definition so I take
  # the description from the w3c
  token ns-name-start-char {
    <[_ A..Z a..z]> || <[\xC0..\xD6]> || <[\xD8..\xF6]> || <[\xF8..\x2FF]> ||
    <[\x370..\x37D]> || <[\x37F..\x1FFF]> || <[\x200C..\x200D]> ||
    <[\x2070..\x218F]> || <[\x2C00..\x2FEF]> || <[\x3001..\xd7ff]> ||
    <[\xf900..\xfdcf]> || <[\xFDF0..\xFFFD]> || <[\x10000..\xEFFFF]>
  }
  token ns-name-char {
    <.name-start-char> | <[- . 0..9]> | <[\xB7]> |
    <[\x0300..\x036F]> | <[\x203F..\x2040]>
  }

  token comment { \s* '#' \N* \n }
}
